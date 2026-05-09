#!/bin/bash
# Structural validation for audit-agent output
# Checks that the audit report files are valid and complete
# Usage: ./validate.sh [output-dir]

set -e
OUTPUT_DIR="${1:-output}"
ERRORS=0

echo "=== audit-agent structural validation ==="
echo ""

# Check required files exist
for FILE in "audit-report.json" "audit-report.md" "audit-report.html"; do
    if [ -f "$OUTPUT_DIR/$FILE" ]; then
        echo "  [PASS] $FILE exists"
    else
        echo "  [FAIL] $FILE missing"
        ERRORS=$((ERRORS + 1))
    fi
done

# Validate audit-report.json structure
echo ""
echo "--- JSON report validation ---"

if [ -f "$OUTPUT_DIR/audit-report.json" ]; then
    if python3 -m json.tool "$OUTPUT_DIR/audit-report.json" > /dev/null 2>&1; then
        echo "  [PASS] Valid JSON"
    else
        echo "  [FAIL] Invalid JSON"
        ERRORS=$((ERRORS + 1))
    fi

    python3 - "$OUTPUT_DIR/audit-report.json" << 'PYEOF'
import json, sys

with open(sys.argv[1]) as f:
    data = json.load(f)

errors = []

# Check required top-level fields
for field in ["agent", "auditedAt", "source", "summary", "results"]:
    if field not in data:
        errors.append(f"Missing top-level field: {field}")

# Check summary
summary = data.get("summary", {})
for field in ["total", "passed", "failed", "warnings", "score"]:
    if field not in summary:
        errors.append(f"Missing summary field: {field}")

# Check score is valid
score = summary.get("score", "")
if score not in ["A", "B", "C", "D", "F", "a", "b", "c", "d", "f"]:
    errors.append(f"Invalid score: {score} (must be A-F)")

# Check results array
results = data.get("results", [])
if not results:
    errors.append("Results array is empty")

for i, result in enumerate(results):
    prefix = f"results[{i}]"
    for field in ["ruleId", "rule", "severity", "chapter", "status"]:
        if field not in result:
            errors.append(f"{prefix} missing field: {field}")

    # Check status is valid
    status = result.get("status", "")
    if status not in ["pass", "fail", "warn", "unknown"]:
        errors.append(f"{prefix} invalid status: {status}")

    # Check severity is valid
    severity = result.get("severity", "")
    if severity not in ["error", "warning"]:
        errors.append(f"{prefix} invalid severity: {severity}")

# Verify counts match
actual_pass = sum(1 for r in results if r.get("status") == "pass")
actual_fail = sum(1 for r in results if r.get("status") == "fail")
actual_warn = sum(1 for r in results if r.get("status") == "warn")

if summary.get("passed") != actual_pass:
    errors.append(f"Summary says {summary.get('passed')} passed but found {actual_pass}")
if summary.get("failed") != actual_fail:
    errors.append(f"Summary says {summary.get('failed')} failed but found {actual_fail}")
if summary.get("warnings") != actual_warn:
    errors.append(f"Summary says {summary.get('warnings')} warnings but found {actual_warn}")

if errors:
    for e in errors:
        print(f"  [FAIL] {e}")
    sys.exit(1)
else:
    score = summary.get("score", "?")
    print(f"  [PASS] All required fields present and valid")
    print(f"  [INFO] Score: {score} | {actual_pass} passed, {actual_fail} failed, {actual_warn} warnings")

PYEOF
fi

# Validate HTML report
echo ""
echo "--- HTML report validation ---"

if [ -f "$OUTPUT_DIR/audit-report.html" ]; then
    # Check it's valid HTML (has basic structure)
    if grep -q "<html" "$OUTPUT_DIR/audit-report.html" && grep -q "</html>" "$OUTPUT_DIR/audit-report.html"; then
        echo "  [PASS] Valid HTML structure"
    else
        echo "  [FAIL] Missing HTML structure"
        ERRORS=$((ERRORS + 1))
    fi

    # Check it's self-contained (has inline CSS)
    if grep -q "<style" "$OUTPUT_DIR/audit-report.html"; then
        echo "  [PASS] Has inline CSS"
    else
        echo "  [WARN] No inline CSS — may not render correctly standalone"
    fi

    # Check no external resource references
    if grep -q "href=\"http" "$OUTPUT_DIR/audit-report.html" || grep -q "src=\"http" "$OUTPUT_DIR/audit-report.html"; then
        echo "  [WARN] Contains external resource references — should be self-contained"
    else
        echo "  [PASS] Self-contained (no external resources)"
    fi
fi

# Validate markdown report
echo ""
echo "--- Markdown report validation ---"

if [ -f "$OUTPUT_DIR/audit-report.md" ]; then
    # Check it has a title
    if grep -q "^# " "$OUTPUT_DIR/audit-report.md"; then
        echo "  [PASS] Has title"
    else
        echo "  [FAIL] Missing title"
        ERRORS=$((ERRORS + 1))
    fi

    # Check it has score
    if grep -qi "score" "$OUTPUT_DIR/audit-report.md"; then
        echo "  [PASS] Mentions score"
    else
        echo "  [FAIL] No score in markdown report"
        ERRORS=$((ERRORS + 1))
    fi
fi

# Summary
echo ""
echo "=== Results ==="
if [ $ERRORS -eq 0 ]; then
    echo "All checks passed."
    exit 0
else
    echo "$ERRORS check(s) failed."
    exit 1
fi
