#!/usr/bin/env bash
# Dev loop for the TrimUI Brick over adb: build, push nextui.elf, restart the launcher.
#
#   ./brick.sh deploy     build tg5040, push nextui.elf, restart NextUI
#   ./brick.sh push       push the last build without rebuilding
#   ./brick.sh restart    restart NextUI (the launcher loop respawns it)
#   ./brick.sh restore    put back the stock nextui.elf (saved as nextui.elf.orig)
#   ./brick.sh log        follow NextUI's log
#   ./brick.sh shell      open a shell on the Brick
#
# The Brick is picked by looking for /mnt/SDCARD/.system/tg5040, so other adb
# devices (phones) are never touched. Set BRICK_SERIAL to skip detection.
set -euo pipefail

cd "$(dirname "$0")"

SYSTEM=/mnt/SDCARD/.system/tg5040
LOG=/mnt/SDCARD/.userdata/tg5040/logs/nextui.txt
ELF=workspace/all/nextui/build/tg5040/nextui.elf

find_brick() {
	if [ -n "${BRICK_SERIAL:-}" ]; then
		echo "$BRICK_SERIAL"
		return
	fi
	for serial in $(adb devices | awk 'NR>1 && $2=="device" {print $1}'); do
		if adb -s "$serial" shell "test -d $SYSTEM" 2>/dev/null; then
			echo "$serial"
			return
		fi
	done
	echo "No Brick found over adb. Plug it in with USB-C and turn it on." >&2
	exit 1
}

push() {
	[ -f "$ELF" ] || { echo "$ELF missing, run ./brick.sh deploy" >&2; exit 1; }
	local serial
	serial=$(find_brick)
	# push next to the live binary and rename over it, so the running copy is never truncated
	adb -s "$serial" push "$ELF" "$SYSTEM/bin/nextui.elf.new"
	adb -s "$serial" shell "mv $SYSTEM/bin/nextui.elf.new $SYSTEM/bin/nextui.elf && chmod +x $SYSTEM/bin/nextui.elf"
	restart "$serial"
}

restart() {
	local serial=${1:-$(find_brick)}
	# SIGKILL, not SIGTERM: SDL turns SIGTERM into SDL_QUIT, which NextUI
	# handles by powering the device off. The launcher loop respawns it.
	adb -s "$serial" shell "killall -9 nextui.elf" || true
	echo "NextUI restarted on $serial"
}

case "${1:-deploy}" in
	deploy)  make build PLATFORM=tg5040 && push ;;
	push)    push ;;
	restart) restart ;;
	restore)
		serial=$(find_brick)
		adb -s "$serial" shell "cp $SYSTEM/bin/nextui.elf.orig $SYSTEM/bin/nextui.elf.new && mv $SYSTEM/bin/nextui.elf.new $SYSTEM/bin/nextui.elf"
		restart "$serial" ;;
	log)     adb -s "$(find_brick)" shell "tail -n 50 -f $LOG" ;;
	shell)   adb -s "$(find_brick)" shell ;;
	*)       sed -n '2,11p' "$0"; exit 1 ;;
esac
