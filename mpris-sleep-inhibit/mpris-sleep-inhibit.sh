#!/usr/bin/env bash
# 監控 MPRIS 播放狀態,播放中就阻止系統睡眠;暫停/停止就放行。

INHIBIT_PID=""

release() {
    if [[ -n "$INHIBIT_PID" ]] && kill -0 "$INHIBIT_PID" 2>/dev/null; then
        kill "$INHIBIT_PID" 2>/dev/null
    fi
    INHIBIT_PID=""
}

cleanup() {
    release
    exit 0
}
trap cleanup TERM INT

while true; do
    if playerctl -a status 2>/dev/null | grep -q Playing; then
        if [[ -z "$INHIBIT_PID" ]] || ! kill -0 "$INHIBIT_PID" 2>/dev/null; then
            systemd-inhibit --what=idle:sleep \
                --who="mpris-sleep-inhibit" \
                --why="有媒體正在播放" \
                --mode=block \
                sleep infinity &
            INHIBIT_PID=$!
        fi
    else
        release
    fi
    sleep 10
done
