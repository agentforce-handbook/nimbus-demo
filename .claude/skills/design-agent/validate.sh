#!/bin/bash
# Structural validation for design-agent output
# Checks that generated files are valid and complete
# Usage: ./validate.sh [output-dir]

set -e
OUTPUT_DIR="${1:-output}"
ERRORS=0

echo "=== design-agent structural validation ==="
echo ""

# Check required files exist
for FILE in "agent-design.json" "deploy.sh" "README.md"; do
    if [ -f "$OUTPUT_DIR/$FILE" ]; then
        echo "  [PASS] $FILE exists"
    else
        echo "  [FAIL] $FILE missing"
        ERRORS=$((ERRORS + 1))
    fi
done

# Check agent script exists (find any .agent file)
AGENT_FILE=$(find "$OUTPUT_DIR/force-app" -name "*.agent" 2>/dev/null | head -1)
if [ -n "$AGENT_FILE" ]; then
    echo "  [PASS] Agent script found: $AGENT_FILE"
else
    echo "  [FAIL] No .agent file found under force-app/"
    ERRORS=$((ERRORS + 1))
fi

# Check bundle XML exists
BUNDLE_FILE=$(find "$OUTPUT_DIR/force-app" -name "*.bundle-meta.xml" 2>/dev/null | head -1)
if [ -n "$BUNDLE_FILE" ]; then
    echo "  [PASS] Bundle metadata found: $BUNDLE_FILE"
else
    echo "  [FAIL] No .bundle-meta.xml found under force-app/"
    ERRORS=$((ERRORS + 1))
fi

# Validate agent-design.json structure
echo ""
echo "--- JSON contract validation ---"

if [ -f "$OUTPUT_DIR/agent-design.json" ]; then
    # Check it's valid JSON
    if python3 -m json.tool "$OUTPUT_DIR/agent-design.json" > /dev/null 2>&1; then
        echo "  [PASS] Valid JSON"
    else
        echo "  [FAIL] Invalid JSON"
        ERRORS=$((ERRORS + 1))
    fi

    # Check required top-level keys
    for KEY in '"\$schema"' '"agent"' '"metadata"'; do
        if python3 -c "import json; d=json.load(open('$OUTPUT_DIR/agent-design.json')); assert $KEY.strip('\"') in str(d)" 2>/dev/null; then
            echo "  [PASS] Key $KEY present"
        fi
    done

    # Check agent has required fields
    python3 << 'PYEOF'
import json, sys

with open(sys.argv[1]) as f:
    data = json.load(f)

agent = data.get("agent", {})
errors = []

# Required agent fields
for field in ["name", "label", "type", "description"]:
    if not agent.get(field):
        errors.append(f"agent.{field} is missing or empty")

# Check subagents exist
subagents = agent.get("subagents", [])
if not subagents:
    errors.append("No subagents defined")

for i, sub in enumerate(subagents):
    prefix = f"subagents[{i}]"

    if not sub.get("name"):
        errors.append(f"{prefix}.name missing")
    if not sub.get("classificationDescription"):
        errors.append(f"{prefix}.classificationDescription missing")
    if not sub.get("instructions"):
        errors.append(f"{prefix}.instructions missing")

    # Check instruction word count
    instructions = sub.get("instructions", "")
    word_count = len(instructions.split())
    if word_count > 1000:
        errors.append(f"{prefix}.instructions is {word_count} words (max 1000)")

    # Check actions have descriptions
    for j, action in enumerate(sub.get("actions", [])):
        if not action.get("description"):
            errors.append(f"{prefix}.actions[{j}].description missing")
        for k, inp in enumerate(action.get("inputs", [])):
            if not inp.get("description"):
                errors.append(f"{prefix}.actions[{j}].inputs[{k}].description missing")
        for k, out in enumerate(action.get("outputs", [])):
            if not out.get("description"):
                errors.append(f"{prefix}.actions[{j}].outputs[{k}].description missing")

    # Check action count
    actions = sub.get("actions", [])
    if len(actions) > 6:
        errors.append(f"{prefix} has {len(actions)} actions (max 6)")

    # Check escalation triggers
    if not sub.get("escalationTriggers"):
        errors.append(f"{prefix}.escalationTriggers missing")

# Check metadata
metadata = data.get("metadata", {})
if not metadata.get("generatedBy"):
    errors.append("metadata.generatedBy missing")

if errors:
    for e in errors:
        print(f"  [FAIL] {e}")
    sys.exit(1)
else:
    print("  [PASS] All required fields present and valid")
    print(f"  [INFO] {len(subagents)} subagents, total actions: {sum(len(s.get('actions',[])) for s in subagents)}")

PYEOF "$OUTPUT_DIR/agent-design.json"
fi

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
