# LAB 17 — Data Pipeline Engineering
#
# The Windows branch uses uv and Windows virtual-environment paths.  The
# Unix branch keeps the original Bash-based commands used by the lab.

VENV := .venv

ifeq ($(OS),Windows_NT)
PY  := $(VENV)/Scripts/python.exe
DBT := $(VENV)/Scripts/dbt.exe
else
SHELL := /bin/bash
PY  := $(VENV)/bin/python
PIP := $(VENV)/bin/pip
DBT := $(VENV)/bin/dbt
endif

export LAB17_DB := $(CURDIR)/warehouse.duckdb
export DBT_PROFILES_DIR := $(CURDIR)/dbt
# Avoid cp1252 errors when the seed scripts print Vietnamese on Windows.
export PYTHONUTF8 := 1

.DEFAULT_GOAL := help
.PHONY: help setup seed seed-extra pipeline verify verify-core quick explain plan dbt-test \
        dbt-docs crash-test compact reset clean

ifeq ($(OS),Windows_NT)

help:  ## danh sách lệnh
	@cmd /c echo.
	@cmd /c echo   LAB 17 - Data Pipeline Engineering
	@cmd /c echo.
	@cmd /c echo     setup          tao moi truong uv va sinh du lieu
	@cmd /c echo     pipeline       chay duong ong mot luot
	@cmd /c echo     verify         chay 3 luot va in bang danh gia
	@cmd /c echo     quick          chay verify mot luot
	@cmd /c echo     dbt-test       chay dbt test
	@cmd /c echo     seed-extra     sinh du lieu bai mo rong
	@cmd /c echo     explain        do rows scanned cua dashboard
	@cmd /c echo     plan           explain + EXPLAIN ANALYZE
	@cmd /c echo     compact        chay bai compact
	@cmd /c echo     crash-test     chay bai consumer crash
	@cmd /c echo     reset          xoa kho DuckDB
	@cmd /c echo     clean          xoa kho va thu muc lam viec
	@cmd /c echo.

setup:  ## venv + thư viện + sinh dữ liệu (chạy một lần)
	@if not exist "$(VENV)" uv venv "$(VENV)" --python 3.11
	@uv pip install --python "$(PY)" -r requirements.txt
	@"$(PY)" seed/generate.py
	@cmd /c echo.
	@cmd /c echo   Xong. Buoc tiep theo: make pipeline roi make verify

seed:  ## sinh lại dữ liệu seed
	@"$(PY)" seed/generate.py

seed-extra:  ## sinh thêm dữ liệu cho bài mở rộng trong EXTRA.md (~30 giây)
	@"$(PY)" seed/generate.py --extra
	@"$(PY)" tools/explain.py --save-baseline

pipeline:  ## chạy đường ống một lượt (14 ngày vận hành)
	@"$(PY)" tools/run_pipeline.py

verify:  ## ⭐ xoá kho, chạy 3 lượt, in bảng chấm — dùng lệnh này liên tục
	@"$(PY)" tools/verify.py

verify-core:  ## chạy 3 nhiệm vụ chính, bỏ qua bài mở rộng dashboard
	@"$(PY)" tools/verify.py --skip-extra

quick:  ## như verify nhưng chỉ 1 lượt (nhanh, không kiểm tra tính ổn định)
	@"$(PY)" tools/verify.py --runs 1

explain:  ## [mở rộng] đo rows scanned của queries/dashboard.sql
	@"$(PY)" tools/explain.py

plan:  ## [mở rộng] explain + in cây EXPLAIN ANALYZE
	@"$(PY)" tools/explain.py --plan

compact:  ## [mở rộng] chạy tools/compact.py
	@"$(PY)" tools/compact.py

dbt-test:  ## chạy dbt test
	@"$(DBT)" test --project-dir dbt --profiles-dir dbt --target-path target --log-path logs

dbt-docs:  ## dựng và mở tài liệu dbt (tuỳ chọn)
	@"$(DBT)" docs generate --project-dir dbt --profiles-dir dbt --target-path target --log-path logs && "$(DBT)" docs serve --project-dir dbt --profiles-dir dbt --target-path target

crash-test:  ## [mở rộng] kịch bản consumer bị giết giữa batch
	@"$(PY)" tools/crash_test.py

reset:  ## xoá kho DuckDB (giữ nguyên seed và data/)
	@if exist "warehouse.duckdb" del /q "warehouse.duckdb"
	@if exist "warehouse.duckdb.wal" del /q "warehouse.duckdb.wal"
	@cmd /c echo   Da xoa kho.

clean:  ## xoá kho + target dbt + thư mục làm việc của crash-test
	@if exist "warehouse.duckdb" del /q "warehouse.duckdb"
	@if exist "warehouse.duckdb.wal" del /q "warehouse.duckdb.wal"
	@if exist "dbt/target" rmdir /s /q "dbt/target"
	@if exist "dbt/logs" rmdir /s /q "dbt/logs"
	@if exist "data/crash" rmdir /s /q "data/crash"
	@cmd /c echo   Da don dep.

else

help:  ## danh sách lệnh
	@echo ""
	@echo "  LAB 17 — Data Pipeline Engineering"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
	  | awk 'BEGIN {FS = ":.*?## "}; {printf "    \033[36m%-14s\033[0m %s\n", $$1, $$2}'
	@echo ""

setup:  ## venv + thư viện + sinh dữ liệu (chạy một lần)
	@test -d $(VENV) || python3 -m venv $(VENV)
	@$(PIP) install -q --upgrade pip
	@$(PIP) install -q -r requirements.txt
	@$(PY) seed/generate.py
	@echo ""
	@echo "  xong. Bước tiếp theo:  make pipeline  rồi  make verify"

seed:  ## sinh lại dữ liệu seed
	@$(PY) seed/generate.py

seed-extra:  ## sinh thêm dữ liệu cho bài mở rộng trong EXTRA.md (~30 giây)
	@$(PY) seed/generate.py --extra
	@$(PY) tools/explain.py --save-baseline

pipeline:  ## chạy đường ống một lượt (14 ngày vận hành)
	@$(PY) tools/run_pipeline.py

verify:  ## ⭐ xoá kho, chạy 3 lượt, in bảng chấm — dùng lệnh này liên tục
	@$(PY) tools/verify.py

verify-core:  ## chạy 3 nhiệm vụ chính, bỏ qua bài mở rộng dashboard
	@$(PY) tools/verify.py --skip-extra

quick:  ## như verify nhưng chỉ 1 lượt (nhanh, không kiểm tra tính ổn định)
	@$(PY) tools/verify.py --runs 1

explain:  ## [mở rộng] đo rows scanned của queries/dashboard.sql
	@$(PY) tools/explain.py

plan:  ## [mở rộng] explain + in cây EXPLAIN ANALYZE
	@$(PY) tools/explain.py --plan

compact:  ## [mở rộng] chạy tools/compact.py
	@$(PY) tools/compact.py

dbt-test:  ## chạy dbt test
	@cd dbt && ../$(DBT) test --profiles-dir . --target-path target --log-path logs

dbt-docs:  ## dựng và mở tài liệu dbt (tuỳ chọn)
	@cd dbt && ../$(DBT) docs generate --profiles-dir . --target-path target --log-path logs \
	  && ../$(DBT) docs serve --profiles-dir . --target-path target

crash-test:  ## [mở rộng] kịch bản consumer bị giết giữa batch
	@$(PY) tools/crash_test.py

reset:  ## xoá kho DuckDB (giữ nguyên seed và data/)
	@rm -f warehouse.duckdb warehouse.duckdb.wal
	@echo "  kho đã xoá."

clean:  ## xoá kho + target dbt + thư mục làm việc của crash-test
	@rm -rf warehouse.duckdb warehouse.duckdb.wal dbt/target dbt/logs data/crash
	@echo "  đã dọn."

endif
