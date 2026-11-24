# INSIDE container, network none. Watchdog kills lake if no new .olean for STALL secs.
set -u
STALL=${STALL:-1800}
( while sleep 120; do
    find .lake/build/ir -name "*.setup.json" 2>/dev/null | while IFS= read -r f; do
      t=".lake/build/lib/lean/${f#.lake/build/ir/}"
      [ "${t%.setup.json}.trace" -nt "$f" ] && rm -f "$f"
    done
  done ) &
CL=$!
(getent hosts github.com >/dev/null && echo "NETWORK REACHABLE - ABORT" && exit 99) || echo "network blocked OK"
lake build Main &
LK=$!
touch /tmp/mark
while kill -0 $LK 2>/dev/null; do
  sleep 60
  if [ -n "$(find .lake/build/lib/lean -name "*.olean" -newer /tmp/mark -print -quit)" ]; then touch /tmp/mark
  elif [ $(( $(date +%s) - $(stat -c %Y /tmp/mark) )) -gt $STALL ]; then
    echo "[watchdog] no new olean for ${STALL}s, killing lake $(date -u +%FT%TZ)"; pkill -TERM -f "lake build"; sleep 20; pkill -KILL lean; pkill -KILL -f "lake build"
  fi
done
wait $LK; RC=$?
kill $CL 2>/dev/null
exit $RC
