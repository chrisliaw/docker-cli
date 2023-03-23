#!/bin/sh
PATH_AND_FILE=$1

THE_PATH="${PATH_AND_FILE%/*}"
FILENAME="${PATH_AND_FILE##*/}"
echo "Script called"
echo "PATH_AND_FILE=$PATH_AND_FILE"
echo "THE_PATH=$THE_PATH"
echo "FILENAME=$FILENAME"

osascript <<EOF

tell application "iTerm"
  activate
  
  # Check to see if we have an open window. If not, open one.
  if (count windows) is 0 then # no window is open. 
    create window with default profile
    delay 0.5
  end if
  
  set currentWindow to current window # get a reference to current window
  
  # We have an open window. 
  tell current session of currentWindow
    if (is processing) or (name is not "bash") then # the current session is busy
      tell currentWindow
        create tab with default profile #- create a new tab
        delay 0.5
      end tell
    end if
  end tell
  
  tell current session of currentWindow
    # make sure we're in the right directory
    write text "cd '$THE_PATH'"
    delay 0.5
    
    # run the script
    set script_string to "$2" & " " & quoted form of "$FILENAME"
    write text script_string
    
  end tell
  
end tell
EOF
