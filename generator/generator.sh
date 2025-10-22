#!/bin/bash
# generator.sh - Auto-generate CSV DB, category INDEX.md, and solutions INDEX.md
# Fully patched with display name support and solutions listing

CONFIG="AUTOGEN.conf"

# --- Helper to read config values ---
get_config() {
    grep "^$1=" "$CONFIG" | cut -d'=' -f2
}

# --- Load config ---
RELATIVE_TO=$(get_config RELATIVE_TO)
DB_FILE=$(get_config CHALLENGES_DB_FILE)
CHALLENGES_ROOT=$(get_config CHALLENGES_ROOT)
DETAILS_FOLDER_NAME=$(get_config CHALLENGES_DETAILS_FOLDER_NAME)
INDEX_FILE_NAME=$(get_config CHALLENGES_INDEX_FILE_NAME)
CATEGORY_TEMPLATE=$(get_config CHALLENGES_INDEX_FILE_TEMPLATE)
SOLUTIONS_FOLDER=$(get_config SOLUTIONS_FOLDER)
SOLUTIONS_TEMPLATE=$(get_config SOLUTIONS_INDEX_FILE_TEMPLATE)
VALID_CATEGORIES=$(get_config VALID_CATEGORIES | tr ',' ' ')
GITHUB_ABSOLUTE=$(get_config GITHUB_ABSOLUTE)

# --- Resolve paths relative to RELATIVE_TO ---
BASE="$RELATIVE_TO"
DB_FILE="$BASE/$DB_FILE"
CHALLENGES_ROOT="$BASE/$CHALLENGES_ROOT"
CATEGORY_TEMPLATE="$BASE/$CATEGORY_TEMPLATE"
SOLUTIONS_TEMPLATE="$BASE/$SOLUTIONS_TEMPLATE"
SOLUTIONS_FOLDER="$BASE/$SOLUTIONS_FOLDER"

# --- Enable nullglob for empty folder safety ---
shopt -s nullglob

# --- CLI usage ---
usage() {
    echo "Usage: $0 <command> [args]"
    echo
    echo "Commands:"
    echo "  update-db                 Scan folders and update the DB (add new challenges)"
    echo "  update-indexes            Generate INDEX.md for all categories based on DB"
    echo "  update-solutions          Generate solutions/INDEX.md"
    echo "  update-all                Update DB, regenerate all category and solutions INDEX.md"
    echo "  status <id> <state> [link]   Update challenge status (notstarted|wip|done)"
    echo "  help                      Show this help message"
}

# --- Step 1: Update DB ---
update_db() {
    mkdir -p "$(dirname "$DB_FILE")"
    [ ! -s "$DB_FILE" ] && echo "index,category,name,status,filepath" > "$DB_FILE"

    for category in $VALID_CATEGORIES; do
        CATEGORY_DIR="$CHALLENGES_ROOT/$category"
        DETAILS_DIR="$CATEGORY_DIR/$DETAILS_FOLDER_NAME"
        DETAILS_DIR="${DETAILS_DIR%/}"
        mkdir -p "$DETAILS_DIR"

        for file in "$DETAILS_DIR"/*.md; do
            [ -f "$file" ] || continue
            FILENAME=$(basename "$file")
            FILEPATH=$(realpath --relative-to="$BASE" "$file")

            # Skip if already in CSV
            if ! grep -q ",$FILENAME," "$DB_FILE"; then
                LAST_ID=$(tail -n1 "$DB_FILE" | cut -d',' -f1)
                NEW_ID=$((LAST_ID+1))
                [ "$LAST_ID" == "index" ] && NEW_ID=1
                echo "$NEW_ID,$category,$FILENAME,⬜,$FILEPATH" >> "$DB_FILE"
            fi
        done
    done
    echo "DB updated."
}

# --- Step 2: Generate category INDEX.md files ---
update_indexes() {
    for category in $VALID_CATEGORIES; do
        CATEGORY_DIR="$CHALLENGES_ROOT/$category"
        INDEX_MD="$CATEGORY_DIR/$INDEX_FILE_NAME"
        mkdir -p "$CATEGORY_DIR"

        TABLE_FILE="/tmp/category_table.md"
        > "$TABLE_FILE"

        while IFS=',' read -r index cat name status filepath; do
            [ "$cat" != "$category" ] && continue
            if [ -f "$BASE/$filepath" ]; then
                if [ "$GITHUB_ABSOLUTE" == "true" ]; then
                 REL_LINK="/${filepath#./}"  # absolute from repo root
                else
                    REL_LINK=$(realpath --relative-to="$CATEGORY_DIR" "$BASE/$filepath")
                fi
                DISPLAY_NAME=$(grep -m1 '^# ' "$BASE/$filepath" 2>/dev/null | sed 's/^# //' | tr -d '\r')
                [ -z "$DISPLAY_NAME" ] && DISPLAY_NAME=$(basename "$filepath" .md | tr '-' ' ')
            else
                REL_LINK="#"
                DISPLAY_NAME=$(basename "$filepath" .md | tr '-' ' ')
            fi

            printf "| %02d | [%s](%s) | %s |\n" "$index" "$DISPLAY_NAME" "$REL_LINK" "$status" >> "$TABLE_FILE"
        done < <(sort -t',' -k1n "$DB_FILE")

        sed "s/{category_name}/$(tr '[:lower:]' '[:upper:]' <<< ${category:0:1})${category:1}/" "$CATEGORY_TEMPLATE" \
            | sed "/{category_table}/{
                r $TABLE_FILE
                d
            }" > "$INDEX_MD"
    done
    echo "Category INDEX.md files generated."
}

# --- Step 3: Generate solutions INDEX.md ---
update_solutions_index() {
    SOLUTIONS_INDEX_MD="$SOLUTIONS_FOLDER/INDEX.md"
    mkdir -p "$(dirname "$SOLUTIONS_INDEX_MD")"

    TMP_TABLES="/tmp/solutions_tables.md"
    > "$TMP_TABLES"

    echo "[DEBUG] Generating solutions index at $SOLUTIONS_INDEX_MD"
    echo "[DEBUG] Using DB file $DB_FILE"

    for lang_dir in "$SOLUTIONS_FOLDER"/*; do
        [ -d "$lang_dir" ] || continue
        LANGUAGE=$(basename "$lang_dir")
        echo "[DEBUG] Processing language folder: $LANGUAGE"

        echo "## $LANGUAGE" >> "$TMP_TABLES"
        echo "" >> "$TMP_TABLES"
        echo "| # | Challenge | Solution |" >> "$TMP_TABLES"
        echo "| --- | --- | --- |" >> "$TMP_TABLES"

        for solution_folder in "$lang_dir"/*; do
            [ -d "$solution_folder" ] || continue
            SOLUTION_NAME=$(basename "$solution_folder")

            # Extract index from folder name, remove leading zeros
            INDEX=$(echo "$SOLUTION_NAME" | grep -o '^[0-9]\+' | sed 's/^0*//')
            echo "[DEBUG] Extracted INDEX from folder '$SOLUTION_NAME': $INDEX"

            # Look up DB row by index
            CHALLENGE_ROW=$(grep "^$INDEX," "$DB_FILE")
            if [ -n "$CHALLENGE_ROW" ]; then
                FILEPATH=$(echo "$CHALLENGE_ROW" | cut -d',' -f5)
                if [ -f "$BASE/$FILEPATH" ]; then
                    DISPLAY_NAME=$(grep -m1 '^# ' "$BASE/$FILEPATH" 2>/dev/null | sed 's/^# //' | tr -d '\r')
                    [ -z "$DISPLAY_NAME" ] && DISPLAY_NAME=$(basename "$FILEPATH" .md)
                    # Challenge link: relative or GitHub-absolute
                    if [ "$GITHUB_ABSOLUTE" == "true" ]; then
                        DETAILS_LINK="/${FILEPATH#./}"  # absolute from repo root
                    else
                        DETAILS_LINK=$(realpath --relative-to="$(dirname "$SOLUTIONS_INDEX_MD")" "$BASE/$FILEPATH")
                    fi
                else
                    DISPLAY_NAME=$(basename "$FILEPATH" .md)
                    DETAILS_LINK="#"
                fi
            else
                DISPLAY_NAME="$SOLUTION_NAME"
                DETAILS_LINK="#"
                echo "[DEBUG] No DB entry found for index $INDEX, using placeholder"
            fi

            # Solution link: no lowercase, optionally GitHub-absolute
            if [ "$GITHUB_ABSOLUTE" == "true" ]; then
                REL_SOLUTION_FOLDER="/solutions/$LANGUAGE/$SOLUTION_NAME"
            else
                REL_SOLUTION_FOLDER=$(realpath --relative-to="$(dirname "$SOLUTIONS_INDEX_MD")" "$solution_folder")
            fi

            # Add table row
            printf "| %02d | [%s](%s) | [%s](%s) |\n" \
                "$INDEX" "$DISPLAY_NAME" "$DETAILS_LINK" "$SOLUTION_NAME" "$REL_SOLUTION_FOLDER" \
                >> "$TMP_TABLES"
        done
        echo "" >> "$TMP_TABLES"
    done

    # Inject table into template
    sed "/{solutions_tables}/{
        r $TMP_TABLES
        d
    }" "$SOLUTIONS_TEMPLATE" > "$SOLUTIONS_INDEX_MD"

    echo "Solutions INDEX.md generated correctly."
}


status_challenge() {
    INDICES_RAW="$1"
    NEW_STATUS="$2"
    LINK="$3"

    if [ -z "$INDICES_RAW" ] || [ -z "$NEW_STATUS" ]; then
        echo "Usage: $0 status <index or comma-separated-list-and-ranges> <notstarted|wip|done> [link-or-folder-if-done]"
        echo "Example: $0 status 1-5,7,10-12 wip"
        exit 1
    fi

    # --- Expand comma-separated ranges into individual indices ---
    EXPANDED_INDICES=()
    IFS=',' read -ra PARTS <<< "$INDICES_RAW"
    for part in "${PARTS[@]}"; do
        part=$(echo "$part" | tr -d '[:space:]') # trim spaces
        if [[ "$part" =~ ^[0-9]+-[0-9]+$ ]]; then
            start=${part%-*}
            end=${part#*-}
            for ((i=start; i<=end; i++)); do
                EXPANDED_INDICES+=("$i")
            done
        elif [[ "$part" =~ ^[0-9]+$ ]]; then
            EXPANDED_INDICES+=("$part")
        else
            echo "⚠️ Invalid range or index: '$part'"
        fi
    done

    # --- Determine status symbol ---
    case "$NEW_STATUS" in
        notstarted) SYMBOL="⬜" ;;
        wip)        SYMBOL="🟨" ;;
        done)       SYMBOL="✅" ;;
        *) echo "Invalid status: $NEW_STATUS"; exit 1 ;;
    esac

    # --- Loop through expanded indices ---
    for INDEX in "${EXPANDED_INDICES[@]}"; do
        LINE_NO=$((INDEX + 1))

        # Extract name & category from CSV (trimming spaces)
        LINE=$(awk -F',' -v line="$LINE_NO" 'NR == line {print $0}' "$DB_FILE" | tr -d '\r')
        CATEGORY=$(echo "$LINE" | awk -F',' '{gsub(/^[ \t]+|[ \t]+$/, "", $2); print $2}')
        NAME=$(echo "$LINE" | awk -F',' '{gsub(/^[ \t]+|[ \t]+$/, "", $3); print $3}')

        NAME=$(basename "$NAME" .md)
        [ -z "$NAME" ] && NAME="Unknown"
        [ -z "$CATEGORY" ] && CATEGORY="?"

        # Replace status
        sed -i "${LINE_NO}s/⬜\|🟨\|✅/$SYMBOL/" "$DB_FILE"

        # Add link if done
        if [ "$SYMBOL" == "✅" ] && [ -n "$LINK" ]; then
            sed -i "${LINE_NO}s|$|,$LINK|" "$DB_FILE"
        fi

        echo "$SYMBOL [$CATEGORY] Challenge #$INDEX ($NAME) marked as $NEW_STATUS"
    done
}


# --- CLI interface ---
COMMAND="$1"
case "$COMMAND" in
    update-db) update_db ;;
    update-indexes) update_indexes ;;
    update-solutions) update_solutions_index ;;
    update-all) update_db; update_indexes; update_solutions_index ;;
    status) shift; status_challenge "$@" ;;
    help|"" ) usage ;;
    *) echo "Unknown command: $COMMAND"; usage ;;
esac

