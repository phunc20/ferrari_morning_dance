# `playback_loop.sh`
This is the main Bash script of this repo and it serves to play songs in
some directory (e.g. `data/dance`) in an infinite loop with a given order
specified in the variable `DANCE_TYPE_CYCLE` in the script. The whole
serves to play songs for dancers in a ball room with as less repetitiveness
as possible.


## Usage
Once the repo downloaded, one can just dry-run the script by

```bash
$ ./playback_loop.sh
```

To play one's own songs, specify your own dance song directory by the option `-d`

```bash
$ ./playback_loop.sh -d path/to/your/own/dance/dir/
```

and eventually fill that directory with more and more songs to dance!💃🕺

For more questions on the usage, please also check out the help message:

```bash
$ ./playback_loop.sh -h
```


## TODO
- [x] Rename the variables named by Gemini
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
    - Bugs
        - [x] Deal with the edge case where, say, `dance/rumba` contains no song file at all.
    - Features
        - [x] Logging: Datetime, logging to a file, logging level, etc.
        - Ask LLMs or google to improve `playback_loop.sh`
            - [x] External command invocation less efficient than Basn parameter expansion?
            - [x] Re-initialization of `RANDOM_INDEX_STR`'s last index may bump into the 1st index from last time. [Think of a stack.] Avoid this.
            - [x] Use nameref instead of (`dance_type: str -> song_paths: str`) dictionary
            - [ ] Replace all `while read` by `readarray`/`mapfile`?
        - Write tests for `playback_loop.sh`
        - [x] Add command-line options to `playback_loop.sh`?
        - [x] Fill up the Usage section in this README to teach users how to use your repo


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
