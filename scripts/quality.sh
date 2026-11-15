#!/usr/bin/env bash
set -euo pipefail
mkdir -p reports
flake8 app.py tests --format=pylint --output-file=reports/flake8.txt
pytest --cov=app --cov-branch --cov-fail-under=80 --cov-report=xml:reports/coverage.xml --cov-report=term-missing --junitxml=reports/junit.xml
