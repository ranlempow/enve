#!/usr/bin/osascript

set plistpath to (path to preferences folder as text) & "com.apple.dock.plist"

tell application "System Events"
    set plistContents to contents of property list file plistpath
    set pListItems to value of plistContents
end tell
set persistentAppsList to |persistent-apps| of pListItems

set dockAppsList to {}
repeat with thisRecord in persistentAppsList
    set item_path to |_CFURLString| of |file-data| of |tile-data| of thisRecord
    -- set item_path to POSIX path of item_path
    set end of dockAppsList to item_path
end repeat

return dockAppsList
