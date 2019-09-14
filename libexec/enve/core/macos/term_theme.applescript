#!/usr/bin/osascript

on run argv
  if length of argv is equal to 0
    set profile to ""
  else
    set profile to item 1 of argv
  end if
  -- set profile to "Basic"
  tell first window of application "Terminal"
    set newTab to selected tab
  end tell
  tell application "Terminal"
    log profile
    -- log (first settings set whose name is profile)
    -- log (name of fisrt settings set)
    -- log (class of (first settings set))
    -- log (name of settings set 8)
    -- log (profile is contained by settings set 8)
    if (profile is equal to "") then
      set current settings of newTab to default settings
    else
      set current settings of newTab to (first settings set whose name is profile)
    end if
  end tell
  return newTab
end run

