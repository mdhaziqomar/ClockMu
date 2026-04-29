#!/bin/sh
# HELP: Alarm clock for muOS set up to 5 alarms with snooze
# ICON: clockmu
# GRID: ClockMu

. /opt/muos/script/var/func.sh

echo app >/tmp/ACT_GO

LOVEDIR="$(GET_VAR "device" "storage/rom/mount")/MUOS/application/ClockMu"
GPTOKEYB="$(GET_VAR "device" "storage/rom/mount")/MUOS/emulator/gptokeyb/gptokeyb2"
BINDIR="$LOVEDIR/bin"

LD_LIBRARY_PATH="$BINDIR/libs.aarch64:$LD_LIBRARY_PATH"
export LD_LIBRARY_PATH

cd "$LOVEDIR" || exit
SET_VAR "SYSTEM" "FOREGROUND_PROCESS" "love"

$GPTOKEYB "love" &
"$BINDIR/love" .
kill -9 "$(pidof gptokeyb2)" 2>/dev/null
