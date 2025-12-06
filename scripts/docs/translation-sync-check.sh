#!/bin/bash
# Check translation synchronization status between Russian, German, and English docs

set -euo pipefail

# Configuration
DOCS_DIR="${1:-docs}"
RU_DIR="$DOCS_DIR"
DE_DIR="$DOCS_DIR/de"
EN_DIR="$DOCS_DIR/en"

# Colors for output
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo "======================================================================================================"
echo "TRANSLATION SYNCHRONIZATION CHECK"
echo "======================================================================================================"
echo ""

# Check if docs directory exists
if [ ! -d "$DOCS_DIR" ]; then
    echo -e "${RED}❌ Error: Documentation directory not found: $DOCS_DIR${NC}"
    exit 1
fi

# Count files in each language
RU_COUNT=$(find "$RU_DIR" -maxdepth 3 -name "*.md" -not -path "*/de/*" -not -path "*/en/*" -not -path "*/archive/*" -not -path "*/node_modules/*" | wc -l | tr -d ' ')
DE_COUNT=$(find "$DE_DIR" -name "*.md" -not -path "*/archive/*" -not -path "*/node_modules/*" 2>/dev/null | wc -l | tr -d ' ' || echo "0")
EN_COUNT=$(find "$EN_DIR" -name "*.md" -not -path "*/archive/*" -not -path "*/node_modules/*" 2>/dev/null | wc -l | tr -d ' ' || echo "0")

echo "Documentation file counts:"
echo "  🇷🇺 Russian (source): $RU_COUNT files"
echo "  🇩🇪 German: $DE_COUNT files"
echo "  🇬🇧 English: $EN_COUNT files"
echo ""

# Calculate sync percentages
if [ "$RU_COUNT" -gt 0 ]; then
    DE_SYNC=$(awk "BEGIN {printf \"%.1f\", ($DE_COUNT / $RU_COUNT) * 100}")
    EN_SYNC=$(awk "BEGIN {printf \"%.1f\", ($EN_COUNT / $RU_COUNT) * 100}")
else
    DE_SYNC="0.0"
    EN_SYNC="0.0"
fi

echo "Translation coverage:"
echo -e "  🇩🇪 German: ${BLUE}${DE_SYNC}%${NC} ($DE_COUNT / $RU_COUNT files)"
echo -e "  🇬🇧 English: ${BLUE}${EN_SYNC}%${NC} ($EN_COUNT / $RU_COUNT files)"
echo ""

# Find missing translations
echo "======================================================================================================"
echo "MISSING TRANSLATIONS"
echo "======================================================================================================"
echo ""

missing_de=0
missing_en=0

while IFS= read -r ru_file; do
    # Get relative path
    rel_path="${ru_file#$RU_DIR/}"

    # Skip special directories
    if [[ "$rel_path" == de/* ]] || [[ "$rel_path" == en/* ]] || [[ "$rel_path" == archive/* ]]; then
        continue
    fi

    # Check if German translation exists
    de_file="$DE_DIR/$rel_path"
    if [ ! -f "$de_file" ]; then
        if [ $missing_de -eq 0 ]; then
            echo "🇩🇪 Missing German translations:"
        fi
        echo "  • $rel_path"
        ((missing_de++))
    fi

    # Check if English translation exists
    en_file="$EN_DIR/$rel_path"
    if [ ! -f "$en_file" ]; then
        if [ $missing_en -eq 0 ]; then
            echo ""
            echo "🇬🇧 Missing English translations:"
        fi
        echo "  • $rel_path"
        ((missing_en++))
    fi
done < <(find "$RU_DIR" -maxdepth 3 -name "*.md" -not -path "*/de/*" -not -path "*/en/*" -not -path "*/archive/*" -not -path "*/node_modules/*")

if [ $missing_de -eq 0 ] && [ $missing_en -eq 0 ]; then
    echo -e "${GREEN}✅ All Russian files have translations!${NC}"
fi

echo ""

# Check for outdated translations
echo "======================================================================================================"
echo "OUTDATED TRANSLATIONS"
echo "======================================================================================================"
echo ""

outdated_de=0
outdated_en=0

while IFS= read -r ru_file; do
    rel_path="${ru_file#$RU_DIR/}"

    # Skip special directories
    if [[ "$rel_path" == de/* ]] || [[ "$rel_path" == en/* ]] || [[ "$rel_path" == archive/* ]]; then
        continue
    fi

    # Check German translation
    de_file="$DE_DIR/$rel_path"
    if [ -f "$de_file" ]; then
        if [[ "$OSTYPE" == "darwin"* ]]; then
            # macOS
            ru_time=$(stat -f "%m" "$ru_file")
            de_time=$(stat -f "%m" "$de_file")
        else
            # Linux
            ru_time=$(stat -c "%Y" "$ru_file")
            de_time=$(stat -c "%Y" "$de_file")
        fi

        if [ "$ru_time" -gt "$de_time" ]; then
            if [ $outdated_de -eq 0 ]; then
                echo "🇩🇪 Outdated German translations:"
            fi

            if [[ "$OSTYPE" == "darwin"* ]]; then
                ru_date=$(stat -f "%Sm" -t "%Y-%m-%d" "$ru_file")
                de_date=$(stat -f "%Sm" -t "%Y-%m-%d" "$de_file")
            else
                ru_date=$(stat -c "%y" "$ru_file" | cut -d' ' -f1)
                de_date=$(stat -c "%y" "$de_file" | cut -d' ' -f1)
            fi

            echo "  • $rel_path"
            echo "    RU modified: $ru_date, DE modified: $de_date"
            ((outdated_de++))
        fi
    fi

    # Check English translation
    en_file="$EN_DIR/$rel_path"
    if [ -f "$en_file" ]; then
        if [[ "$OSTYPE" == "darwin"* ]]; then
            ru_time=$(stat -f "%m" "$ru_file")
            en_time=$(stat -f "%m" "$en_file")
        else
            ru_time=$(stat -c "%Y" "$ru_file")
            en_time=$(stat -c "%Y" "$en_file")
        fi

        if [ "$ru_time" -gt "$en_time" ]; then
            if [ $outdated_en -eq 0 ]; then
                echo ""
                echo "🇬🇧 Outdated English translations:"
            fi

            if [[ "$OSTYPE" == "darwin"* ]]; then
                ru_date=$(stat -f "%Sm" -t "%Y-%m-%d" "$ru_file")
                en_date=$(stat -f "%Sm" -t "%Y-%m-%d" "$en_file")
            else
                ru_date=$(stat -c "%y" "$ru_file" | cut -d' ' -f1)
                en_date=$(stat -c "%y" "$en_file" | cut -d' ' -f1)
            fi

            echo "  • $rel_path"
            echo "    RU modified: $ru_date, EN modified: $en_date"
            ((outdated_en++))
        fi
    fi
done < <(find "$RU_DIR" -maxdepth 3 -name "*.md" -not -path "*/de/*" -not -path "*/en/*" -not -path "*/archive/*" -not -path "*/node_modules/*")

if [ $outdated_de -eq 0 ] && [ $outdated_en -eq 0 ]; then
    echo -e "${GREEN}✅ All translations are up to date!${NC}"
fi

echo ""

# Summary
echo "======================================================================================================"
echo "SUMMARY"
echo "======================================================================================================"
echo ""
echo "Missing translations:"
echo "  🇩🇪 German: $missing_de files"
echo "  🇬🇧 English: $missing_en files"
echo ""
echo "Outdated translations:"
echo "  🇩🇪 German: $outdated_de files"
echo "  🇬🇧 English: $outdated_en files"
echo ""

# Determine exit status
if [ $missing_de -gt 0 ] || [ $missing_en -gt 0 ] || [ $outdated_de -gt 0 ] || [ $outdated_en -gt 0 ]; then
    echo -e "${YELLOW}⚠️  Translation synchronization issues found${NC}"
    echo ""
    echo "Targets:"
    echo "  🇩🇪 German: 80% coverage (current: ${DE_SYNC}%)"
    echo "  🇬🇧 English: 70% coverage (current: ${EN_SYNC}%)"
    echo ""

    # Check if targets are met
    de_target_met=$(echo "$DE_SYNC >= 80.0" | bc -l)
    en_target_met=$(echo "$EN_SYNC >= 70.0" | bc -l)

    if [ "$de_target_met" -eq 1 ] && [ "$en_target_met" -eq 1 ]; then
        echo -e "${GREEN}✅ Translation coverage targets met!${NC}"
        exit 0
    else
        echo -e "${RED}❌ Translation coverage targets NOT met${NC}"
        exit 1
    fi
else
    echo -e "${GREEN}✅ All translations are synchronized!${NC}"
    exit 0
fi
