#!/usr/bin/env bash
# Dev loop for the TrimUI Brick over adb: build, push nextui.elf, restart the launcher.
#
#   ./brick.sh deploy     build tg5040, push nextui.elf, restart NextUI
#   ./brick.sh push       push the last build without rebuilding
#   ./brick.sh restart    restart NextUI (the launcher loop respawns it)
#   ./brick.sh restore    put back the stock nextui.elf (saved as nextui.elf.orig)
#   ./brick.sh log        follow NextUI's log
#   ./brick.sh shell      open a shell on the Brick
#   ./brick.sh press BTN… press buttons: a b x y l1 r1 select start menu up down left right
#   ./brick.sh shot [png] save a screenshot of the Brick
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

# One evdev record (struct input_event on aarch64: 16 byte timeval, u16 type,
# u16 code, s32 value) as printf octal escapes. The kernel stamps the time.
ev() {
	local type=$1 code=$2 value=$(( $3 & 0xffffffff )) out="" i
	for i in $(seq 16); do out+='\0'; done
	for byte in $(( type & 255 )) $(( type >> 8 )) $(( code & 255 )) $(( code >> 8 )) \
		$(( value & 255 )) $(( (value >> 8) & 255 )) $(( (value >> 16) & 255 )) $(( value >> 24 )); do
		out+=$(printf '\\%03o' "$byte")
	done
	printf '%s' "$out"
}

# Press and release buttons on the "TRIMUI Player1" virtual pad NextUI reads
# (an Xbox 360 layout made by trimui_inputd), eg. ./brick.sh press select right right a
press() {
	local serial dev btn type code value syn
	serial=$(find_brick)
	dev=$(adb -s "$serial" shell "grep -A4 'TRIMUI Player1' /proc/bus/input/devices | grep -o 'event[0-9]*'" | tr -d '\r')
	[ -n "$dev" ] || { echo "TRIMUI Player1 input device not found" >&2; exit 1; }
	syn=$(ev 0 0 0)
	for btn in "$@"; do
		case "$btn" in
			b)      type=1 code=0x130 value=1 ;;
			a)      type=1 code=0x131 value=1 ;;
			y)      type=1 code=0x133 value=1 ;;
			x)      type=1 code=0x134 value=1 ;;
			l1)     type=1 code=0x136 value=1 ;;
			r1)     type=1 code=0x137 value=1 ;;
			select) type=1 code=0x13a value=1 ;;
			start)  type=1 code=0x13b value=1 ;;
			menu)   type=1 code=0x13c value=1 ;;
			up)     type=3 code=0x11 value=-1 ;; # ABS_HAT0Y
			down)   type=3 code=0x11 value=1 ;;
			left)   type=3 code=0x10 value=-1 ;; # ABS_HAT0X
			right)  type=3 code=0x10 value=1 ;;
			*) echo "unknown button: $btn" >&2; exit 1 ;;
		esac
		# one adb call per button, a long run of presses overflows adb's command length
		# the -c check keeps a bad name from creating a plain file in /dev/input
		adb -s "$serial" shell "[ -c /dev/input/$dev ] || exit 1; printf '$(ev $type $code $value)$syn' >/dev/input/$dev; usleep 80000; printf '$(ev $type $code 0)$syn' >/dev/input/$dev; usleep 250000"
	done
}

# Save the Brick's screen as a png on this machine
shot() {
	local serial out=${1:-${TMPDIR:-/tmp}/brick-shot.png}
	serial=$(find_brick)
	adb -s "$serial" shell "/usr/trimui/bin/fbscreencap /tmp/brick-shot.png >/dev/null 2>&1"
	adb -s "$serial" pull /tmp/brick-shot.png "$out" >/dev/null
	echo "$out"
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
	press)   shift; press "$@" ;;
	shot)    shift; shot "$@" ;;
	*)       sed -n '2,13p' "$0"; exit 1 ;;
esac
