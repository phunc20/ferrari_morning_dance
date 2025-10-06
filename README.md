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


## Lesson Learned
- If you want to write a function, say, `your_terrific_func`, and to make use of
  that function's stdout via, say, `value=$(your_terrific_func arg1 arg2)`,
  then your debug/logging message from inside the function should look like
  `echo "this is a logging message" >&2` (because otherwise the function's
  stdout will be messed up.)
