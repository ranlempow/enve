#!/usr/bin/osascript

-- tell application "System Events" to get the title of every window of every process

-- tell application "System Events" to get the title of every window of (processes whose name is "sublime_merge")
-- —

--  tell application "System Environment"
-- activate

-- usage: getwintitle.applescript --list
--        getwintitle.applescript PROC --list
--        getwintitle.applescript PROC
--        getwintitle.applescript PROC TITLE [--raise]
--
-- return:
--


on run argv
    set procName to item 1 of argv
    tell application "System Events"
        if procName = "--list" then
            return get the name of every process
        else
            set ps to (get id of application processes whose name contains procName)
        end if
        if ps = {} then
            return
        end if
        if (count of argv) = 1 then
            return (get name of application processes whose name contains procName)
        end if

        set windowName to item 2 of argv

        set appName to null
        set w_names to {}
        repeat with proc in ps
            tell application process id proc
                set theList to (get name of every window)
                repeat with a from 1 to (length of theList)
                    if windowName = "--list" then
                        -- return get the name of every window
                        -- repeat with w_name in (get name of every window)
                        set end of w_names to (item a of theList)
                    else
                        if (item a of theList) contains windowName then
                            if (count of argv) = 3 and (item 3 of argv) = "--raise" then
                                set frontmost to true
                                perform action "AXRaise" of (first window whose name = (item a of theList))
                            end if
                            return item a of theList
                        end if
                    end if
                end repeat
            end tell
        end repeat
        if windowName = "--list" then
            return w_names
        end if
    end tell
    -- return (path to frontmost application as text)
    -- return {appName, appPath}
    -- tell application appName
    --     activate
    -- end tell
end run
