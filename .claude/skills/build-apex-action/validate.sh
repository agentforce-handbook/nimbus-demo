#!/bin/bash
# Structural validation for build-apex-action output
# Checks that generated Apex files are valid and complete
# Usage: ./validate.sh [output-dir]

set -e
OUTPUT_DIR="${1:-output}"
ERRORS=0

echo "=== build-apex-action structural validation ==="
echo ""

# Check required files exist
for FILE in "deploy.sh" "README.md"; do
    if [ -f "$OUTPUT_DIR/$FILE" ]; then
        echo "  [PASS] $FILE exists"
    else
        echo "  [FAIL] $FILE missing"
        ERRORS=$((ERRORS + 1))
    fi
done

# Find Apex class files
CLS_FILES=$(find "$OUTPUT_DIR/force-app" -name "*.cls" ! -name "*Test.cls" 2>/dev/null)
TEST_FILES=$(find "$OUTPUT_DIR/force-app" -name "*Test.cls" 2>/dev/null)
META_FILES=$(find "$OUTPUT_DIR/force-app" -name "*.cls-meta.xml" 2>/dev/null)

if [ -n "$CLS_FILES" ]; then
    echo "  [PASS] Apex class found: $CLS_FILES"
else
    echo "  [FAIL] No Apex class (.cls) found"
    ERRORS=$((ERRORS + 1))
fi

if [ -n "$TEST_FILES" ]; then
    echo "  [PASS] Test class found: $TEST_FILES"
else
    echo "  [FAIL] No test class (*Test.cls) found"
    ERRORS=$((ERRORS + 1))
fi

# Check each .cls has a matching .cls-meta.xml
echo ""
echo "--- Metadata file pairing ---"
for CLS in $(find "$OUTPUT_DIR/force-app" -name "*.cls" 2>/dev/null); do
    META="${CLS}-meta.xml"
    if [ -f "$META" ]; then
        echo "  [PASS] $CLS has metadata"
    else
        echo "  [FAIL] $CLS missing metadata ($META)"
        ERRORS=$((ERRORS + 1))
    fi
done

# Validate Apex patterns
echo ""
echo "--- Apex pattern validation ---"

for CLS in $(find "$OUTPUT_DIR/force-app" -name "*.cls" ! -name "*Test.cls" 2>/dev/null); do
    echo "  Checking: $(basename $CLS)"

    # Check for @InvocableMethod
    if grep -q "@InvocableMethod" "$CLS"; then
        echo "    [PASS] Has @InvocableMethod"
    else
        echo "    [FAIL] Missing @InvocableMethod"
        ERRORS=$((ERRORS + 1))
    fi

    # Check for @InvocableVariable with descriptions
    INV_VARS=$(grep -c "@InvocableVariable" "$CLS" 2>/dev/null || echo 0)
    INV_WITH_DESC=$(grep -c "@InvocableVariable.*description=" "$CLS" 2>/dev/null || echo 0)
    if [ "$INV_VARS" -eq "$INV_WITH_DESC" ] && [ "$INV_VARS" -gt 0 ]; then
        echo "    [PASS] All $INV_VARS @InvocableVariable have descriptions"
    elif [ "$INV_VARS" -gt 0 ]; then
        echo "    [FAIL] $INV_WITH_DESC of $INV_VARS @InvocableVariable have descriptions"
        ERRORS=$((ERRORS + 1))
    fi

    # Check for 'with sharing'
    if grep -q "with sharing" "$CLS"; then
        echo "    [PASS] Uses 'with sharing'"
    else
        echo "    [FAIL] Missing 'with sharing' — FLS not enforced"
        ERRORS=$((ERRORS + 1))
    fi

    # Check for errorMessage output
    if grep -qi "errorMessage\|error_message\|errormsg" "$CLS"; then
        echo "    [PASS] Has error message output"
    else
        echo "    [FAIL] No error message output field"
        ERRORS=$((ERRORS + 1))
    fi

    # Check for exception handling (try/catch)
    if grep -q "try {" "$CLS" || grep -q "try{" "$CLS"; then
        echo "    [PASS] Has try/catch error handling"
    else
        echo "    [WARN] No try/catch found — exceptions may reach the agent"
    fi

    # Check no thrown exceptions reach caller
    THROWS=$(grep -c "throw " "$CLS" 2>/dev/null || echo 0)
    if [ "$THROWS" -eq 0 ]; then
        echo "    [PASS] No thrown exceptions"
    else
        echo "    [WARN] Found $THROWS throw statement(s) — verify they're inside catch blocks only"
    fi
done

# Validate test class
echo ""
echo "--- Test class validation ---"

for TEST in $(find "$OUTPUT_DIR/force-app" -name "*Test.cls" 2>/dev/null); do
    echo "  Checking: $(basename $TEST)"

    if grep -q "@IsTest" "$TEST"; then
        echo "    [PASS] Has @IsTest annotation"
    else
        echo "    [FAIL] Missing @IsTest"
        ERRORS=$((ERRORS + 1))
    fi

    TEST_METHODS=$(grep -c "@IsTest" "$TEST" 2>/dev/null || echo 0)
    # Subtract 1 for the class-level annotation
    TEST_METHODS=$((TEST_METHODS - 1))
    if [ "$TEST_METHODS" -ge 2 ]; then
        echo "    [PASS] Has $TEST_METHODS test methods"
    else
        echo "    [FAIL] Only $TEST_METHODS test method(s) — need at least 2 (happy path + error)"
        ERRORS=$((ERRORS + 1))
    fi

    if grep -q "Assert\." "$TEST" || grep -q "System.assert" "$TEST"; then
        echo "    [PASS] Has assertions"
    else
        echo "    [FAIL] No assertions found"
        ERRORS=$((ERRORS + 1))
    fi
done

# Check deploy.sh is executable
echo ""
echo "--- Deploy script validation ---"
if [ -f "$OUTPUT_DIR/deploy.sh" ]; then
    if [ -x "$OUTPUT_DIR/deploy.sh" ]; then
        echo "  [PASS] deploy.sh is executable"
    else
        echo "  [FAIL] deploy.sh is not executable"
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
