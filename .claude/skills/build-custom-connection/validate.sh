#!/bin/bash
# Structural validation for build-custom-connection output
# Checks that generated metadata files are valid and complete
# Usage: ./validate.sh [output-dir]

set -e
OUTPUT_DIR="${1:-output}"
ERRORS=0

echo "=== build-custom-connection structural validation ==="
echo ""

# Check required files exist
for FILE in "deploy.sh" "README.md" "sfdx-project.json"; do
    if [ -f "$OUTPUT_DIR/$FILE" ]; then
        echo "  [pass] $FILE exists"
    else
        echo "  [fail] $FILE missing"
        ERRORS=$((ERRORS + 1))
    fi
done

# Check package.xml exists
if [ -f "$OUTPUT_DIR/unpackaged/package.xml" ]; then
    echo "  [pass] package.xml exists"
else
    echo "  [fail] unpackaged/package.xml missing"
    ERRORS=$((ERRORS + 1))
fi

# Check for at least one AiResponseFormat
echo ""
echo "--- AiResponseFormat validation ---"

RF_FILES=$(find "$OUTPUT_DIR/unpackaged/aiResponseFormats" -name "*.aiResponseFormat" 2>/dev/null)
if [ -n "$RF_FILES" ]; then
    RF_COUNT=$(echo "$RF_FILES" | wc -l | tr -d '[:space:]')
    echo "  [pass] Found $RF_COUNT response format(s)"

    # Validate each response format has required XML elements
    for RF in $RF_FILES; do
        BASENAME=$(basename "$RF")
        if grep -q "<description>" "$RF" && grep -q "<input>" "$RF" && grep -q "<masterLabel>" "$RF"; then
            echo "  [pass] $BASENAME has required elements"
        else
            echo "  [fail] $BASENAME missing required elements (description, input, masterLabel)"
            ERRORS=$((ERRORS + 1))
        fi

        # Validate input field is valid JSON
        INPUT_JSON=$(sed -n 's/.*<input>\(.*\)<\/input>.*/\1/p' "$RF" 2>/dev/null)
        if [ -n "$INPUT_JSON" ]; then
            if echo "$INPUT_JSON" | python3 -m json.tool > /dev/null 2>&1; then
                echo "  [pass] $BASENAME input is valid JSON"
            else
                echo "  [fail] $BASENAME input is not valid JSON"
                ERRORS=$((ERRORS + 1))
            fi
        fi
    done
else
    echo "  [fail] No .aiResponseFormat files found"
    ERRORS=$((ERRORS + 1))
fi

# Check for AiSurface
echo ""
echo "--- AiSurface validation ---"

SURFACE_FILES=$(find "$OUTPUT_DIR/unpackaged/aiSurfaces" -name "*.aiSurface" 2>/dev/null)
if [ -n "$SURFACE_FILES" ]; then
    echo "  [pass] AiSurface file found"

    for SF in $SURFACE_FILES; do
        BASENAME=$(basename "$SF")
        if grep -q "<surfaceType>Custom</surfaceType>" "$SF"; then
            echo "  [pass] $BASENAME has Custom surfaceType"
        else
            echo "  [fail] $BASENAME missing Custom surfaceType"
            ERRORS=$((ERRORS + 1))
        fi

        if grep -q "<responseFormats>" "$SF"; then
            echo "  [pass] $BASENAME has responseFormats"
        else
            echo "  [fail] $BASENAME missing responseFormats"
            ERRORS=$((ERRORS + 1))
        fi
    done
else
    echo "  [fail] No .aiSurface file found"
    ERRORS=$((ERRORS + 1))
fi

# Check deploy.sh is executable
echo ""
echo "--- Deploy script validation ---"
if [ -f "$OUTPUT_DIR/deploy.sh" ]; then
    if [ -x "$OUTPUT_DIR/deploy.sh" ]; then
        echo "  [pass] deploy.sh is executable"
    else
        echo "  [fail] deploy.sh is not executable"
        ERRORS=$((ERRORS + 1))
    fi

    # Check deploy.sh uses --metadata-dir (not --manifest)
    if grep -q "\-\-metadata-dir" "$OUTPUT_DIR/deploy.sh"; then
        echo "  [pass] deploy.sh uses --metadata-dir"
    else
        echo "  [fail] deploy.sh should use --metadata-dir (not --manifest)"
        ERRORS=$((ERRORS + 1))
    fi
fi

# Validate sfdx-project.json
echo ""
echo "--- Project config validation ---"
if [ -f "$OUTPUT_DIR/sfdx-project.json" ]; then
    if python3 -m json.tool "$OUTPUT_DIR/sfdx-project.json" > /dev/null 2>&1; then
        echo "  [pass] sfdx-project.json is valid JSON"
    else
        echo "  [fail] sfdx-project.json is invalid JSON"
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
