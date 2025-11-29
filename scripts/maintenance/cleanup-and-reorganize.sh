#!/usr/bin/env bash

# ERNI-KI Scripts Cleanup and Reorganization
# Moves deprecated scripts, removes duplicates, standardizes structure

set -euo pipefail

# Load common library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/common.sh
source "${SCRIPT_DIR}/../lib/common.sh"

# =============================================================================
# Configuration
# =============================================================================

PROJECT_ROOT=$(get_project_root)
ARCHIVE_DIR="${PROJECT_ROOT}/scripts/archive"
DRY_RUN="${DRY_RUN:-0}"

# =============================================================================
# Helper Functions
# =============================================================================

archive_script() {
    local script="$1"
    local reason="$2"

    log_info "Archiving: $script ($reason)"

    if [[ "$DRY_RUN" == "1" ]]; then
        log_debug "[DRY RUN] Would archive: $script"
        return
    fi

    ensure_directory "$ARCHIVE_DIR"

    local filename
    filename=$(basename "$script")
    local target="${ARCHIVE_DIR}/${filename}"

    # Add timestamp if file exists
    if [[ -f "$target" ]]; then
        local timestamp
        timestamp=$(date +"%Y%m%d_%H%M%S")
        target="${ARCHIVE_DIR}/${filename%.sh}_${timestamp}.sh"
    fi

    mv "$script" "$target"
    log_success "Archived: $script -> $target"
}

move_to_tests() {
    local script="$1"
    local test_type="${2:-integration}"

    log_info "Moving test script: $script -> tests/$test_type/"

    if [[ "$DRY_RUN" == "1" ]]; then
        log_debug "[DRY RUN] Would move to tests/$test_type/"
        return
    fi

    local filename
    filename=$(basename "$script")
    local target_dir="${PROJECT_ROOT}/tests/${test_type}"

    ensure_directory "$target_dir"

    mv "$script" "${target_dir}/${filename}"
    log_success "Moved: $script -> tests/$test_type/$filename"
}

# =============================================================================
# Cleanup Operations
# =============================================================================

cleanup_empty_scripts() {
    log_info "Finding empty scripts..."

    local count=0
    while IFS= read -r -d '' file; do
        if [[ ! -s "$file" ]]; then
            log_warn "Found empty script: $file"
            archive_script "$file" "empty file"
            count=$((count + 1))
        fi
    done < <(find "${PROJECT_ROOT}/scripts" -type f \( -name "*.sh" -o -name "*.py" \) -print0)

    log_info "Archived $count empty scripts"
}

cleanup_test_scripts() {
    log_info "Moving test scripts to tests/ directory..."

    local test_scripts=(
        "${PROJECT_ROOT}/scripts/test-redis-connections.sh"
        "${PROJECT_ROOT}/scripts/core/maintenance/test-admin-models-display.sh"
        "${PROJECT_ROOT}/scripts/infrastructure/security/test-nginx-config.sh"
        "${PROJECT_ROOT}/scripts/infrastructure/security/test-letsencrypt-staging.sh"
        "${PROJECT_ROOT}/scripts/monitoring/test-alert-delivery.sh"
    )

    local count=0
    for script in "${test_scripts[@]}"; do
        if [[ -f "$script" ]]; then
            move_to_tests "$script" "integration"
            count=$((count + 1))
        fi
    done

    log_info "Moved $count test scripts"
}

cleanup_deprecated_scripts() {
    log_info "Archiving deprecated scripts..."

    # Scripts marked as deprecated or old
    local deprecated_patterns=(
        "old"
        "backup"
        "deprecated"
        "temp"
        "tmp"
    )

    local count=0
    for pattern in "${deprecated_patterns[@]}"; do
        while IFS= read -r -d '' file; do
            log_warn "Found deprecated script: $file"
            archive_script "$file" "matches pattern: $pattern"
            count=$((count + 1))
        done < <(find "${PROJECT_ROOT}/scripts" -type f -name "*${pattern}*" -print0 2>/dev/null)
    done

    log_info "Archived $count deprecated scripts"
}

consolidate_top_level_scripts() {
    log_info "Consolidating top-level scripts..."

    # Move utility scripts to proper subdirectories
    local utility_scripts=(
        "${PROJECT_ROOT}/scripts/remove-all-emoji.py:utilities"
        "${PROJECT_ROOT}/scripts/validate-no-emoji.py:utilities"
        "${PROJECT_ROOT}/scripts/add-missing-frontmatter.py:docs"
        "${PROJECT_ROOT}/scripts/fix-deprecated-metadata.py:docs"
        "${PROJECT_ROOT}/scripts/prettier-run.sh:utilities"
    )

    local count=0
    for mapping in "${utility_scripts[@]}"; do
        IFS=':' read -r script target_dir <<< "$mapping"

        if [[ -f "$script" ]]; then
            local filename
            filename=$(basename "$script")
            local target="${PROJECT_ROOT}/scripts/${target_dir}/${filename}"

            log_info "Moving: $script -> scripts/$target_dir/"

            if [[ "$DRY_RUN" != "1" ]]; then
                ensure_directory "$(dirname "$target")"
                mv "$script" "$target"
                log_success "Moved: $filename -> $target_dir/"
            fi

            count=$((count + 1))
        fi
    done

    log_info "Consolidated $count top-level scripts"
}

standardize_shebang() {
    log_info "Standardizing shebang lines..."

    local count=0

    # Python scripts should use #!/usr/bin/env python3
    while IFS= read -r -d '' file; do
        local first_line
        first_line=$(head -n 1 "$file")

        if [[ ! "$first_line" =~ ^#!/usr/bin/env\ python3 ]]; then
            log_debug "Updating shebang in: $file"

            if [[ "$DRY_RUN" != "1" ]]; then
                # Create temp file with correct shebang
                {
                    echo "#!/usr/bin/env python3"
                    tail -n +2 "$file"
                } > "${file}.tmp"
                mv "${file}.tmp" "$file"
                chmod +x "$file"
            fi

            count=$((count + 1))
        fi
    done < <(find "${PROJECT_ROOT}/scripts" -type f -name "*.py" -print0)

    # Shell scripts should use #!/usr/bin/env bash
    while IFS= read -r -d '' file; do
        local first_line
        first_line=$(head -n 1 "$file")

        if [[ ! "$first_line" =~ ^#!/usr/bin/env\ bash ]]; then
            log_debug "Updating shebang in: $file"

            if [[ "$DRY_RUN" != "1" ]]; then
                # Preserve existing pipefail block to avoid duplicates
                local has_pipefail=0
                if grep -q "set -euo pipefail" "$file"; then
                    has_pipefail=1
                fi

                {
                    echo "#!/usr/bin/env bash"
                    echo ""
                    if [[ "$has_pipefail" -eq 0 ]]; then
                        echo "set -euo pipefail"
                        echo ""
                    fi
                    tail -n +2 "$file"
                } > "${file}.tmp"
                mv "${file}.tmp" "$file"
                chmod +x "$file"
            fi

            count=$((count + 1))
        fi
    done < <(find "${PROJECT_ROOT}/scripts" -type f -name "*.sh" -print0)

    log_info "Standardized $count shebang lines"
}

add_error_handling() {
    log_info "Adding error handling to shell scripts..."

    local count=0

    while IFS= read -r -d '' file; do
        # Check if file has set -euo pipefail
        if ! grep -q "set -euo pipefail" "$file"; then
            log_debug "Adding error handling to: $file"

            if [[ "$DRY_RUN" != "1" ]]; then
                # Insert after shebang
                {
                    head -n 1 "$file"
                    echo ""
                    echo "set -euo pipefail"
                    tail -n +2 "$file"
                } > "${file}.tmp"
                mv "${file}.tmp" "$file"
            fi

            count=$((count + 1))
        fi
    done < <(find "${PROJECT_ROOT}/scripts" -type f -name "*.sh" -print0)

    log_info "Added error handling to $count scripts"
}

# =============================================================================
# Main
# =============================================================================

usage() {
    cat <<EOF
ERNI-KI Scripts Cleanup and Reorganization

Usage: $(basename "$0") [options]

Options:
  --dry-run    Show what would be done without making changes
  -h, --help   Show this help message

Operations:
  1. Archive empty scripts
  2. Move test scripts to tests/ directory
  3. Archive deprecated scripts
  4. Consolidate top-level scripts
  5. Standardize shebang lines
  6. Add error handling to shell scripts

Environment:
  DRY_RUN=1   Same as --dry-run flag
EOF
}

main() {
    local dry_run_flag=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --dry-run)
                DRY_RUN=1
                dry_run_flag=" [DRY RUN]"
                shift
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            *)
                log_error "Unknown argument: $1"
                usage
                exit 1
                ;;
        esac
    done

    log_info "Starting scripts cleanup and reorganization${dry_run_flag}"

    if [[ "$DRY_RUN" == "1" ]]; then
        log_warn "DRY RUN MODE: No changes will be made"
    fi

    # Run cleanup operations
    cleanup_empty_scripts
    cleanup_test_scripts
    cleanup_deprecated_scripts
    consolidate_top_level_scripts
    standardize_shebang
    add_error_handling

    log_success "Cleanup and reorganization completed!"

    if [[ "$DRY_RUN" == "1" ]]; then
        log_info "Run without --dry-run to apply changes"
    fi
}

main "$@"
