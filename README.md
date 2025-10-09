## Usage


## TODO
- [ ] Rename the variables named by Gemini
- [ ] Take note of what you learned into another repo (called `bash-man` maybe)
- Make the execution of the script more user-friendly on Fedora for elderly
    - [x] Auto-execution of the script upon logging
- Teach Mom
    - [ ] Bluetooth connection btw laptop and speaker
    - [ ] How to next song
    - [ ] How to pause the music
    - [ ] How to turn off the music altogether
    - [ ] How to restart the laptop
- Verbessern `playback_loop.sh`
    - [ ] Logging: Datetime, logging to a file, logging level, etc.
    - Ask LLMs or google to improve `playback_loop.sh`
        - [ ] External command invocation less efficient than Basn parameter expansion?
        - [ ] Re-initialization of `RANDOM_INDEX_STR`'s 1st index may bump into the last index from last time. Avoid this.
        - [ ] Use nameref instead of (`dance_type: str -> song_paths: str`) dictionary
        - [ ] Replace all `while read` by `readarray`/`mapfile`?
        - [ ] Logging level and option to print to stdout (instead of exclusively to log file)
    - Write tests for `playback_loop.sh`
    - [ ] Fill up the Usage section in this README to teach users how to use your repo


## Lesson Learned
- If you want to write a function, say, `your_terrific_func`, and to make use of
  that function's stdout via, say, `value=$(your_terrific_func arg1 arg2)`,
  then your debug/logging message from inside the function should look like
  `echo "this is a logging message" >&2` (because otherwise the function's
  stdout will be messed up.)


## Questions to LLMs
Hey, I have written this Bash script to help my aunt's dancing room to play
randomly dancing songs according to some fixed order of dance types
(to be precise, "tango" "chachacha" "waltz" "jitterbug" "tango" "chachacha" "waltz" "jitterbug" "rumba").

Could you help me improve this script by suggesting me places where I can modify, e.g.
to improve the speed/efficiency of execution, better refactoring, better logging, etc.

Below is my script btw triple ticks:
