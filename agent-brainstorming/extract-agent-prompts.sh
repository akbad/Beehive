#!/usr/bin/env bash

# Claude subagent prompt extraction script
#
# Prerequisites:
#   - Standard Unix tools (awk, basename, find, mkdir)
#
# Usage:
#   ./extract-agent-prompts.sh <path>
#
# Arguments:
#   <path>    A single .md subagent file or a directory containing .md files.
#
# Purpose:
#   Takes a Claude subagent template .md file with YAML frontmatter (or a directory
#   of such files) and creates a new directory called `extracted-agent-prompts/`.
#   This new directory will contain copies of the subagent files with the
#   YAML frontmatter removed.

set -e  # exit on error

# --- ARGUMENT PARSING ---

if [[ "$#" -ne 1 ]] || [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]; then
    # Extract the header comment block to show as help text:
    # 1. selects lines from line 2 up until first blank line
    # 2. removes leading `#` chars
    # 3. prints the resulting help message
    sed -n '2,/^$/p' "$0" | sed 's/^# //g'
    exit 0
fi

# --- CONFIG ---

# Output directory for the processed prompts
readonly OUTPUT_DIR="extracted-agent-prompts"

# Colors
readonly GREEN='\033[0;32m'
readonly BLUE='\033[0;34m'
readonly RED='\033[0;31m'
readonly NC='\033[0m'

# --- HELPERS ---

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Processes a single agent file, stripping its YAML frontmatter.
# Arguments:
#   $1: The path to the input markdown file.
process_file() {
    local input_file="$1"

    if [[ ! -f "$input_file" ]] || [[ ! -r "$input_file" ]]; then
        log_error "Input file is not a readable file: $input_file"
        return 1
    fi

    local filename
    filename=$(basename "$input_file")
    local output_file="$OUTPUT_DIR/$filename"

    log_info "Processing '$filename'..."

    # Use awk to remove the YAML block (from the first '---' to the second '---').
    # The logic toggles a flag `in_yaml`. It only prints lines when the flag is 0 (not in yaml).
    # The `next` command skips the `---` delimiter lines themselves.
    # The `sub()` function trims leading whitespace from the first line after the YAML.
    awk '
        /^---$/ { in_yaml = !in_yaml; if (in_yaml) first_line_after_yaml=1; next }
        !in_yaml {
            if (first_line_after_yaml) {
                sub(/^[ \t]+/, "");
                first_line_after_yaml=0;
            }
            print
        }
    ' "$input_file" > "$output_file"
}

# --- MAIN LOGIC ---

main() {
    local input_path="$1"

    if [[ ! -e "$input_path" ]]; then
        log_error "Input path does not exist: $input_path"
        exit 1
    fi

    log_info "Creating output directory at ./$OUTPUT_DIR/"
    mkdir -p "$OUTPUT_DIR"

    if [[ -d "$input_path" ]]; then
        log_info "Input is a directory. Processing all .md files in the top-level..."
        # Find .md files only in the top-level of the directory
        find "$input_path" -maxdepth 1 -type f -name "*.md" | while read -r file; do
            process_file "$file"
        done
    elif [[ -f "$input_path" ]]; then
        log_info "Input is a single file."
        process_file "$input_path"
    else
        log_error "Input path is not a file or a directory: $input_path"
        exit 1
    fi

    echo ""
    log_success "Done. Extracted prompts are in the './$OUTPUT_DIR/' directory."
}

# Run the main function with all script arguments
main "$@"