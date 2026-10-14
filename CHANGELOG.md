# NextUI Brick changelog

A personal NextUI build for the TrimUI Brick (`tg5040`), kept on the `custom`
branch of this fork. Versions are tagged `brick-vX.Y.Z` so they don't clash
with upstream's `vX.Y.Z` tags. The current version lives in `VERSION` and shows
up in Settings > About.

New changes go under "Unreleased"; cutting a release moves them under a new
version, bumps `VERSION` and tags the commit.

## Unreleased

## 0.5.0

- Turning Wifi or Bluetooth on/off no longer freezes the UI (wifi_init.sh
  takes ~6s to start Wifi): the script runs in the background and the hint
  reads "Turning on..." until it's done.
- The settings page no longer hides the Updater; it and the Pak Store were
  removed from the device instead.
- Settings page: Wifi, Bluetooth, Reboot and Power off are a row of icon
  buttons along the bottom instead of list rows. Down from the last app moves
  into the row, left/right picks, up goes back; the hint says what A does
  ("Turn off", "Reboot"...). Wifi/Bluetooth icons follow their state.

## 0.4.0

- Game switcher has no BACK: it's the home screen, SELECT flips to the list.
- MENU opens the settings page from the switcher too, and closing it returns
  there. MENU Settings replaces the POWER Sleep hint in the switcher and list.
- Switcher art fits the screen again (black bars when the ratio differs); the
  0.3.0 full-screen crop cut off too much of the box art.
- Long game names in the switcher wrap onto a second line.
- Button hints and the wifi/battery pill are drawn at 2/3 size with
  sentence-case labels ("Back", not "BACK"), in every app built on api.c.
- "Keep awake over USB" became "Keep awake when plugged in": a charger or a
  computer keeps the device awake, even with a full battery. On by default.
- Settings > About shows the NextUI Brick version.
- brick.sh pushes every api.c app (Settings, Game Tracker, Input, LedControl,
  Bootlogo), refuses to press buttons while another app is open
  (`BRICK_FORCE=1` overrides) and writes version.txt on the device.

## 0.3.0

- Plugged in with a full battery no longer autosleeps or powers off (the
  battery reports not charging once full).
- Switcher art covers the whole screen; the fade-in no longer stretches it.
- No box art in the game list by default, it lives in the switcher.
- brick.sh pushes minarch.elf too and keeps the stock binaries as `.orig`.

## 0.2.0

- The game switcher lists every game with box art from `.media`, recently
  played first. A game copied into two folders (SFC/SUPA) shows once.
- Boot into the switcher; leaving a game or pak returns to where it was opened.
- Switcher names come from each folder's `map.txt`, like the game list.
- brick.sh can press buttons and take screenshots over adb.

## 0.1.0

- The game list shows only systems: no Recently Played, Collections or Tools.
- MENU opens a settings page: the Settings app, every Tools pak, Wifi and
  Bluetooth toggles with their state, Reboot, Poweroff.
- The stock Updater is hidden, it would install upstream over this build.
- brick.sh: build, push and restart over adb.
