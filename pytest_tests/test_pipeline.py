"""End-to-end checks of the dbt project: a clean build passes and the marts add up, and bad data is really caught by the tests."""
import csv
import os
import shutil
import subprocess
import sys
from pathlib import Path

import duckdb
import pytest

ROOT = Path(__file__).resolve().parents[1]


def dbt_exe():
    local = Path(sys.executable).parent / ("dbt.exe" if os.name == "nt" else "dbt")
    return str(local) if local.exists() else (shutil.which("dbt") or "dbt")


def copy_project(tmp_path):
    dst = tmp_path / "project"
    shutil.copytree(ROOT, dst, ignore=shutil.ignore_patterns("target", "logs", "*.duckdb", "*.duckdb.wal", ".venv", "__pycache__", ".pytest_cache", ".git", "pytest_tests"))
    return dst


def build(project):
    return subprocess.run([dbt_exe(), "build", "--profiles-dir", ".", "--project-dir", "."], cwd=project, capture_output=True, text=True, timeout=300)


def test_a_clean_build_passes_and_the_marts_account_for_every_book(tmp_path):
    p = copy_project(tmp_path)
    r = build(p)
    assert r.returncode == 0, r.stdout[-2000:]
    seed_rows = sum(1 for _ in csv.DictReader(open(p / "seeds" / "raw_books.csv", encoding="utf-8")))
    con = duckdb.connect(str(p / "warehouse.duckdb"), read_only=True)
    assert con.execute("select count(*) from stg_books").fetchone()[0] == seed_rows
    assert con.execute("select sum(books) from mart_category_price_stats").fetchone()[0] == seed_rows
    assert con.execute("select sum(books) from mart_rating_distribution").fetchone()[0] == seed_rows
    assert con.execute("select count(*) from dim_categories").fetchone()[0] == 8
    assert abs(con.execute("select sum(share_pct) from mart_rating_distribution").fetchone()[0] - 100) < 0.5
    assert {r[0] for r in con.execute("select distinct price_band from fct_books").fetchall()} <= {"budget", "standard", "premium"}
    con.close()


@pytest.mark.parametrize("bad_row, expected", [
    ("Mystery,Broken price,-5.00,True,3,https://example.test/a,2026-11-16", "positive_value"),
    ("Mystery,Broken rating,10.00,True,9,https://example.test/b,2026-11-16", "accepted_values"),
    ("Mystery,Duplicate url,10.00,True,3,{dup_url},2026-11-16", "unique"),
])
def test_bad_data_is_caught_by_the_tests(tmp_path, bad_row, expected):
    p = copy_project(tmp_path)
    seed = p / "seeds" / "raw_books.csv"
    rows = list(csv.DictReader(open(seed, encoding="utf-8")))
    with open(seed, "a", encoding="utf-8", newline="") as f:
        f.write(bad_row.format(dup_url=rows[0]["url"]) + "\n")
    r = build(p)
    assert r.returncode != 0, "dbt build should fail on bad data"
    assert expected in r.stdout
