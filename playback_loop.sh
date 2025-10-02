#!/bin/bash

# ==============================================================================
# CONFIGURATION
# ==============================================================================

# 1. Root directory containing the dance folders (chachacha, tango, etc.)
#DANCE_DIR="./dance"  # relative path
DANCE_DIR="/home/phunc20/corbeille/ferrari_1F_dance/dance"  # absolute path

# 2. Command-line media player.
#    Change 'mpv' to 'mpg123', 'ffplay', or your preferred player.
PLAYER="mpv"

# 3. The specified order of dance types.
PLAYLIST_ORDER=(
    "tango" "chachacha" "waltz" "jitterbug" "tango" "chachacha" "waltz" "jitterbug" "rumba"
)

# 4. Accepted file extensions (case-insensitive)
FILE_PATTERNS=("mp3" "ogg" "wav" "flac" "m4a")

# ==============================================================================
# GLOBAL STATE (Requires Bash 4.0+ for Associative Arrays)
# ==============================================================================

# DANCE_SONGS: Maps dance type (string) -> all song paths (newline-separated string)
declare -A DANCE_SONGS

# PLAYED_SONGS: Maps song path (string) -> 1 (used as a set to track played status)
declare -A PLAYED_SONGS

declare -A RANDOM_INDEX_STR
declare -A SONGS_COUNT

# ALL_SONGS_COUNT: Total number of unique songs found in the library.
ALL_SONGS_COUNT=0

# ==============================================================================
# FUNCTIONS
# ==============================================================================

# Function to discover all songs and store them in the DANCE_SONGS map.
load_songs() {
    if [ ! -d "$DANCE_DIR" ]; then
        echo "Error: Dance directory '$DANCE_DIR' not found." >&2
        exit 1
    fi

    echo "--- Playlist Loader ---"
    echo "(# songs found)"
    
    local dance_type
    local file_list_string=""
    local unique_types
    local pattern_regex
    
    # Build a single regex pattern for 'find -iregex'
    # E.g., ".*\.mp3|.*\.ogg|..."
    #pattern_regex=$(IFS=\|; echo "${FILE_PATTERNS[*]}")
    pattern_regex=$(printf "%s\|" "${FILE_PATTERNS[@]}")
    pattern_regex="${pattern_regex%\\|}" # Remove the trailing pipe
    pattern_regex=".*\.\($pattern_regex\)"
    #pattern_regex=".*.($pattern_regex)"
    #echo "pattern_regex = $pattern_regex"

    # Use a unique set of dance types to avoid redundant file searches
    #echo "PLAYLIST_ORDER = $PLAYLIST_ORDER"
    declare -A unique_types
    for type in "${PLAYLIST_ORDER[@]}"; do
        unique_types[$type]=1
    done

    # debugging echo
    #echo "unique_types[@] = ${unique_types[@]}"
    #echo "!unique_types[@] = ${!unique_types[@]}"

    for dance_type in "${!unique_types[@]}"; do
        local count=0
        file_list_string=""
        
        # Use 'find' to robustly handle filenames with spaces and special characters.
        # -iregex is used for case-insensitive pattern matching on the full path.
	#echo "DANCE_DIR/dance_type = $DANCE_DIR/$dance_type"
	#echo "pattern_regex = '$pattern_regex'"
	#find "$DANCE_DIR/$dance_type" -maxdepth 1 -type f -regex "$pattern_regex" -print0
	#find "$DANCE_DIR/$dance_type" -maxdepth 1 -type f -regex "$pattern_regex"
	#echo "(Before find) count = $count"
        #find "$DANCE_DIR/$dance_type" -maxdepth 1 -type f \
        #    -regex "$pattern_regex" -print0 | while IFS= read -r -d $'\0' file; do
        #    #-regex "$pattern_regex" | while IFS= read -r file; do
        #    #-regex "$pattern_regex" -print0 | while IFS= read -r -d $'\0' file; do
        #    
        #    # Store the song path separated by newline
	#    echo "file = $file"
        #    file_list_string+="$file"$'\n'
        #    count=$((count + 1))
	#    echo "(In for loop) count = $count"
        #    ALL_SONGS_COUNT=$((ALL_SONGS_COUNT + 1))
        #done

        #file_list_string=$(find "$DANCE_DIR/$dance_type" -maxdepth 1 -type f \
        #    -iregex "$pattern_regex" -print0 | tr '\0' '\n')
        file_list_string=$(find "$DANCE_DIR/$dance_type" -maxdepth 1 -type f \
            -iregex "$pattern_regex")
        if [[ -n "$file_list_string" ]]; then
            # grep -c . counts lines that contain at least one character.
            count=$(echo -n "$file_list_string" | grep -c .)
        fi

	SONGS_COUNT[$dance_type]=$count
	RANDOM_INDEX_STR[$dance_type]=$(shuf -i 0-$(( $count-1 )) | tr '\n' ' ')
        # debugging echo
	#echo "file_list_string = $file_list_string"
	#echo "(After find) count = $count"
	#echo "\${RANDOM_INDEX_STR[@]} = ${RANDOM_INDEX_STR[@]}"
        if [ "$count" -gt 0 ]; then
            DANCE_SONGS[$dance_type]="$file_list_string"
            echo "  $dance_type: $count"
            ALL_SONGS_COUNT=$((ALL_SONGS_COUNT + count))
        else
            echo "Warning: No songs found for '$dance_type' in '$DANCE_DIR/$dance_type'. Skipping." >&2
        fi
    done

    if [ "$ALL_SONGS_COUNT" -eq 0 ]; then
        echo "Fatal Error: No songs found. Exiting." >&2
        exit 1
    fi
    #echo "--- Playlist Loader: $ALL_SONGS_COUNT total unique songs loaded. ---"
    echo "  total: $ALL_SONGS_COUNT"
}


pop_song() {
    local DANCE_TYPE=$1
    local song_list_string="${DANCE_SONGS[$DANCE_TYPE]}"

    # debugging echo
    #echo "\${song_list_string[@]} = ${song_list_string[@]}" >&2
    #echo "\${#song_list_string[@]} = ${#song_list_string[@]}" >&2
    if [[ -z "$song_list_string" ]]; then
        return 1
    fi

    local -a this_type_songs=()
    while IFS= read -r -d $'\n' song_path; do
        this_type_songs+=("$song_path")
    done <<< "$song_list_string"
    index=$(echo "${RANDOM_INDEX_STR[$DANCE_TYPE]}" | awk '{print $NF}')
    song_path=${this_type_songs[$index]}
    # debugging echo
    echo "\${song_list_string} = ${song_list_string}" >&2
    echo "index = $index" >&2
    echo "song_path = $song_path" >&2

    ##IFS=$'\n' read -ra song_path_array <<< "$song_list_string"
    ## debugging echo
    #echo "Look here:" >&2
    ##echo $(tail -n 1 <(echo $song_list_string)) >&2
    ##echo "\$song_list_string = $song_list_string" >&2
    ##echo
    ##echo "tail = $(tail -1 <(printf $song_list_string))" >&2
    ##echo "tail = $(tail -1 <(echo $song_list_string))" >&2
    #local while_tail
    #IFS=$'\n'
    #while read -r path; do
    #    while_tail=$path
    #done <<< "$song_list_string"
    ##echo "\$while_tail = $while_tail" >&2

    ## debugging echo
    echo "(Before) ${RANDOM_INDEX_STR[$DANCE_TYPE]}" >&2
    RANDOM_INDEX_STR[$DANCE_TYPE]=$(echo "${RANDOM_INDEX_STR[$DANCE_TYPE]}" | awk '{NF--; print}')
    #echo "${RANDOM_INDEX_STR[$DANCE_TYPE]}" | awk '{NF--; print}' >&2
    echo "(After ) ${RANDOM_INDEX_STR[$DANCE_TYPE]}" >&2

    #echo "$while_tail"
    echo "$song_path"
    return 0
}


# Function to select an unplayed song for a given dance type, 
# and handles the global reset if all songs have been played.
select_song_and_mark_played() {
    local DANCE_TYPE=$1
    local song_list_string="${DANCE_SONGS[$DANCE_TYPE]}"
    local -a available_songs=()
    #local song_path=""
    local selected_song=""

    # debugging echo
    #echo "song_list_string = $song_list_string" >&2
    #echo "\${PLAYED_SONGS[@]} = ${PLAYED_SONGS[@]}" >&2

    if [[ -z "$song_list_string" ]]; then
        return 1
    fi

    # 1. Check for Global Reset
    if [ ${#PLAYED_SONGS[@]} -ge "$ALL_SONGS_COUNT" ]; then
        echo ">>> All $ALL_SONGS_COUNT songs played once. Resetting global 'played' list. <<<"
        # Reset the global associative array
        declare -gA PLAYED_SONGS=()
    fi


    # 2. Filter available songs: Create an array of UNPLAYED songs for the current type
    while IFS= read -r -d $'\n' song_path; do

        if [[ -z "${PLAYED_SONGS[$song_path]}" ]]; then
            available_songs+=("$song_path")
        fi
        # debugging echo
	#echo "song_path = $song_path" >&2
	#echo "\${PLAYED_SONGS[\$song_path]} = '${PLAYED_SONGS[$song_path]}'" >&2
	#echo "available_songs = $available_songs" >&2
    done <<< "$song_list_string"

    # debugging echo
    #echo "\${PLAYED_SONGS[@]} = ${PLAYED_SONGS[@]}" >&2
    #echo "\${available_songs[@]} = ${available_songs[@]}" >&2

    if [ ${#available_songs[@]} -gt 0 ]; then
        # SCENARIO A: UNPLAYED SONGS AVAILABLE - Select randomly from the unplayed list
        local index=$((RANDOM % ${#available_songs[@]}))
        selected_song="${available_songs[$index]}"
    else
        # SCENARIO B: ALL SONGS IN THIS CATEGORY PLAYED - Force a repeat
        echo "Notice: All songs of type '$DANCE_TYPE' played recently. Selecting a song to repeat."

        # 1. Load ALL songs for this dance type into an array
        local -a all_category_songs=()
        while IFS= read -r -d $'\n' song_path; do
            all_category_songs+=("$song_path")
        done <<< "$song_list_string"

        if [ ${#all_category_songs[@]} -gt 0 ]; then
            # 2. Select randomly from the full list
            local index=$((RANDOM % ${#all_category_songs[@]}))
            selected_song="${all_category_songs[$index]}"
        else
            # Should not happen if DANCE_SONGS was properly loaded
            echo "Error: Category '$DANCE_TYPE' unexpectedly empty." >&2
            return 1
        fi
    fi
    
    # 3. Mark the selected song as played (or re-mark if it was a repeat)
    PLAYED_SONGS[$selected_song]=1

    # debugging echo
    #echo "\${PLAYED_SONGS[@]} = ${PLAYED_SONGS[@]}" >&2

    
    echo "$selected_song" # Output the file path
    return 0
}

# The main loop that runs the playlist sequence repeatedly.
main_loop() {
    local song_file
    local playlist_index=0
    local order_length=${#PLAYLIST_ORDER[@]}

    echo -e "\n--- Starting Dance Sequence Loop ---"
    
    while true; do
        local DANCE_TYPE="${PLAYLIST_ORDER[$playlist_index]}"
        local current_step=$((playlist_index + 1))

        # debugging echo
        #echo "PLAYED_SONGS = ${PLAYED_SONGS[@]}"
        echo -e "\n[Step $current_step/$order_length] | Dance: $DANCE_TYPE | Played: ${#PLAYED_SONGS[@]}/$ALL_SONGS_COUNT"

        # Try to select an unplayed song for the current dance type
        #song_file=$(select_song_and_mark_played "$DANCE_TYPE")
        #song_file=$(pop_song "$DANCE_TYPE")
        # debugging echo
        #echo "\${PLAYED_SONGS[@]} = ${PLAYED_SONGS[@]}" >&2
        #local status=$?

        #if [ "$status" -eq 0 ]; then
        #    # Success scenario
        #    echo "-> Playing: $(basename "$song_file")"

        #    "$PLAYER" --keep-open=no "$song_file"

        #    if [ $? -ne 0 ]; then
        #        echo "Error: Failed to play song using '$PLAYER'. Please check your player installation." >&2
        #    fi
        #elif [ "$status" -eq 1 ]; then
        #    # Failure scenario (only happens if the category itself is empty)
        #    : # Do nothing, just move to the next item in the order
        #fi

        # Try not to use a subshell
	# 1/ Check whether index is empty (i.e. all poped out)
        # debugging echo
        echo "(Before) \${RANDOM_INDEX_STR[\$DANCE_TYPE]} = '${RANDOM_INDEX_STR[$DANCE_TYPE]}'"
        #read -p "Press Enter to continue..."
	if [[ -z "${RANDOM_INDEX_STR[$DANCE_TYPE]}" ]]; then
	    echo "with DANCE_TYPE = $DANCE_TYPE, \$RANDOM_INDEX_STR[\$DANCE_TYPE] is empty"
	    read -p "Please press Enter to reinitialize RANDOM_INDEX_STR."
	    count=${SONGS_COUNT[$DANCE_TYPE]}
	    # debug
	    echo "\$count = $count"
	    RANDOM_INDEX_STR[$DANCE_TYPE]=$(shuf -i 0-$(( $count-1 )) | tr '\n' ' ')
	    echo "(Initialization) \${RANDOM_INDEX_STR[$DANCE_TYPE]} = ${RANDOM_INDEX_STR[$DANCE_TYPE]}"
	fi
        # debugging echo
        local -a this_type_songs=()
        while IFS= read -r -d $'\n' song_path; do
            this_type_songs+=("$song_path")
        done <<< "${DANCE_SONGS[$DANCE_TYPE]}"
        echo "this_type_songs = ${this_type_songs[@]}"

        index=$(echo "${RANDOM_INDEX_STR[$DANCE_TYPE]}" | awk '{print $NF}')
        echo "index = $index"
        song_path=${this_type_songs[$index]}
        echo "song_path = $song_path"
        RANDOM_INDEX_STR[$DANCE_TYPE]=$(echo "${RANDOM_INDEX_STR[$DANCE_TYPE]}" | awk '{NF--; print}')
        echo "(After ) \${RANDOM_INDEX_STR[\$DANCE_TYPE]} = '${RANDOM_INDEX_STR[$DANCE_TYPE]}'"
	if [ -f "$song_path" ]; then
            echo "-> Playing: $(basename "$song_path")"
            "$PLAYER" --keep-open=no "$song_path"

            if [ $? -ne 0 ]; then
                echo "Error: Failed to play song using '$PLAYER'. Please check your player installation." >&2
            fi
	else
            echo "Error: File path '$song_path' not exist." >&2
	fi

        playlist_index=$(( (playlist_index + 1) % order_length ))
        
    done
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
