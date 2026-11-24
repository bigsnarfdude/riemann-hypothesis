# runs INSIDE container, network none
set -u
( while sleep 60; do
    find .lake/build/ir -name "*.setup.json" 2>/dev/null | while IFS= read -r f; do
      t=".lake/build/lib/lean/${f#.lake/build/ir/}"
      [ "${t%.setup.json}.trace" -nt "$f" ] && rm -f "$f" && echo x
    done | wc -l | sed "s/^/[cleanup] removed /"
  done ) &
CL=$!
echo "[net check]"; (getent hosts github.com && echo "NETWORK REACHABLE - ABORT") || echo "network blocked OK"
date +"[start] %F %T"
timeout 1200 lake build Lemmata; echo "[lake exit $?]"
date +"[end] %F %T"
kill $CL
