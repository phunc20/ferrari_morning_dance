#!/bin/bash

# ==============================================================================
# CONFIGURATION
# ==============================================================================

# 1. Root directory containing the dance folders (chachacha, tango, etc.)
#DANCE_DIR="./dance"  # relative path
DANCE_DIR="$HOME/Music/dance"  # absolute path

# 2. Command-line media player.
#    Change 'mpv' to 'mpg123', 'ffplay', or your preferred player.
PLAYER="mpv"

# 3. The specified order of dance types.
DANCE_TYPE_CYCLE=(
    "tango" "chachacha" "waltz" "jitterbug" "tango" "chachacha" "waltz" "jitterbug" "rumba"
)

# 4. Accepted file extensions (case-insensitive via `find` -iname/-iregex)
FILE_EXTENSIONS=("mp3" "ogg" "wav" "flac" "m4a")

# 5. Save the default IFS (since we will alter its value often)
default_IFS=$IFS

# ==============================================================================
# GLOBAL STATE (Requires Bash 4.0+ for Associative Arrays)
# ==============================================================================

# BASENAME_PLAYED_COUNT: song file basename (string) -> (# times played so far) (int)
declare -Ai BASENAME_PLAYED_COUNT

# RANDOM_INDEX_STR: Maps dance type (string) -> `shuf -i 0-(#songs -1)` (string)
# Each of RANDOM_INDEX_STR's value works like a stack, although they are strings.
declare -A RANDOM_INDEX_STR

# DANCE_TYPE_SONGS_COUNT: Maps dance type (string) -> count (int)
declare -A DANCE_TYPE_SONGS_COUNT

# ALL_SONGS_COUNT: Total number of unique songs found in the library.
declare -i ALL_SONGS_COUNT=0

# ==============================================================================
# LOGGING
# ==============================================================================

DATETIME=$(date '+%Y-%m-%d_%H:%M:%S')

SOURCE="${BASH_SOURCE[0]}"
while [ -L "$SOURCE" ]; do # Resolve $SOURCE until the file is no longer a symlink
  REPO_DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  # If $SOURCE was a relative symlink, we need to resolve it
  # relative to the symlink's parent directory
  [[ $SOURCE != /* ]] && SOURCE="$REPO_DIR/$SOURCE"
done
REPO_DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
LOG_DIR="$REPO_DIR/log"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/$DATETIME.log"

log_message() {
    local level="$1"
    #local message="$2"
    local message="${@:2:$#-1}"
    #echo -e "$(date '+%Y-%m-%d %H:%M:%S') [$level] $message" | tee -a "$LOG_FILE"
    echo -e "$(date '+%Y-%m-%d %H:%M:%S') [$level] $message" >> "$LOG_FILE"
}

# ==============================================================================
# FUNCTIONS
# ==============================================================================

load_songs() {
    if [ ! -d "$DANCE_DIR" ]; then
        echo "Error: Dance directory '$DANCE_DIR' not found." >&2
        exit 1
    fi

    echo "--- Playlist Loader ---"
    echo "(# songs found)"

    local dance_type
    local pattern_regex

    pattern_regex=$(printf "%s\|" "${FILE_EXTENSIONS[@]}")
    # Remove the trailing pipe
    pattern_regex="${pattern_regex%\\|}"
    # Complete the regex
    pattern_regex=".*\.\($pattern_regex\)"

    # Use a dictionary (i.e. associative array)
    # This is faster than external command combination of sort and uniq.
    local -A _unique_dance_types
    for dance_type in "${DANCE_TYPE_CYCLE[@]}"; do
        _unique_dance_types["$dance_type"]=1
    done
    # Take all the keys and make it into an array
    local -a unique_dance_types=("${!_unique_dance_types[@]}")

    log_message "DEBUG" "\${unique_dance_types[@]} = ${unique_dance_types[@]}"
    local -i count

    for dance_type in "${unique_dance_types[@]}"; do
        local -a song_paths
        mapfile -t song_paths < <(
            find "$DANCE_DIR/$dance_type" -maxdepth 1 -type f -iregex "$pattern_regex"
        )
        count=${#song_paths[@]}

        DANCE_TYPE_SONGS_COUNT[$dance_type]=$count
        ALL_SONGS_COUNT+=$count

        if [ "$count" -gt 0 ]; then
            local -n song_path_array="DANCE_SONGS_$dance_type"
            # Copy array content (to avoid overwriting)
            song_path_array=("${song_paths[@]}")
            initialize_RANDOM_INDEX_STR "$dance_type"
            echo "  $dance_type: $count"
        else
            # TODO: Change this echo into logging
            echo "Warning: No songs found for '$dance_type' in '$DANCE_DIR/$dance_type'. Skipping." >&2
        fi
    done

    if [ "$ALL_SONGS_COUNT" -eq 0 ]; then
        echo "Fatal Error: No songs found. Exiting." >&2
        exit 1
    fi
    echo "  total: $ALL_SONGS_COUNT"
}


main_loop() {
    local song_file
    local -i playlist_index=0
    local -i cycle_length=${#DANCE_TYPE_CYCLE[@]}

    echo -e "\n--- Starting Dance Sequence Loop ---"

    local -i total_played_count=0
    local -Ai avoid_index_array
    while true; do
        local dance_type="${DANCE_TYPE_CYCLE[$playlist_index]}"
        local current_step=$((playlist_index + 1))
        printf "\nStep: $current_step/$cycle_length | Dance: $dance_type"

        # 1/ Check whether the index stack in question is empty (i.e. all poped out)
        if [[ -z "${RANDOM_INDEX_STR[$dance_type]}" ]]; then
            initialize_RANDOM_INDEX_STR "$dance_type" "${avoid_index_array[$dance_type]}"
            log_message "INFO" "\${RANDOM_INDEX_STR[\"$dance_type\"]} = ${RANDOM_INDEX_STR[$dance_type]} after re-initialization"
        fi

        local -n song_path_array="DANCE_SONGS_$dance_type"
        index="${RANDOM_INDEX_STR[$dance_type]##* }"
        song_path=${song_path_array[$index]}
        #log_message "DEBUG" "\${song_path_array[@]} =\n${song_path_array[@]}"
        log_message "DEBUG" "\${song_path_array[@]} =\n$(printf "  %s\n" "${song_path_array[@]}")"
        log_message "DEBUG" "\$index = $index"
        log_message "DEBUG" "\$song_path = $song_path"

        RANDOM_INDEX_STR[$dance_type]="${RANDOM_INDEX_STR[$dance_type]% *}"

        # In case where RANDOM_INDEX_STR[$dance_type] is left with only one index,
        # The above pop action will fail to achieve its mission.
        # The next `if` serves to fix this.
        if [[ "$index" == "${RANDOM_INDEX_STR[$dance_type]}" ]]; then
            RANDOM_INDEX_STR[$dance_type]=""
            avoid_index_array[$dance_type]=$index
        fi

        if [ -f "$song_path" ]; then
            total_played_count+=1
            song_basename=$(basename "$song_path")
            BASENAME_PLAYED_COUNT[$song_basename]+=1
            echo -e "\n-> Playing: $song_basename"
            echo    "   (# Played = ${BASENAME_PLAYED_COUNT[$song_basename]}/$total_played_count)"
            "$PLAYER" --keep-open=no "$song_path"

            if [ $? -ne 0 ]; then
                echo "Error: Failed to play song using '$PLAYER'. Please check your player installation." >&2
            fi
        else
            echo "Error: File path '$song_path' not exist." >&2
        fi

        playlist_index=$(( (playlist_index + 1) % cycle_length ))
    done
}

# TODO
# 1/ Deal with the case in which users pass non-int avoid_index
initialize_RANDOM_INDEX_STR() {
    local dance_type="$1"
    local -i count=${DANCE_TYPE_SONGS_COUNT[$dance_type]}
    if [ $count -eq 1 ]; then
        RANDOM_INDEX_STR[$dance_type]="0"
	return 0
    fi

    if [ $# -lt 2 ]; then
        shuffled_indices=($(shuf -i 0-$(( $count-1 ))))
    else
        local -i avoid_index="$2"
        while true; do
            shuffled_indices=($(shuf -i 0-$(( $count-1 ))))
            if [ ${shuffled_indices[-1]} -ne $avoid_index ]; then
                break
            fi
        done
    fi

    IFS=' '
    RANDOM_INDEX_STR[$dance_type]="${shuffled_indices[*]}"
    IFS="$default_IFS"
}

# ==============================================================================
# SCRIPT EXECUTION
# ==============================================================================

# Ensure the script is run with Bash (not sh)
if [ -z "$BASH_VERSION" ]; then
    echo "Error: This script requires Bash 4.0 or higher due to associative array usage." >&2
    exit 1
fi

load_songs

main_loop
