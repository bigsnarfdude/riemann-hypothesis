#!/bin/bash
# HOST driver: restarts the sandboxed build until lake exits 0 (max 12 attempts)
LOG=$HOME/rh/logs-full-build.txt; TL=$HOME/rh/full-build-timeline.txt
OLEANS() { find $HOME/rh/work/grh/src/lean/.lake/build/lib/lean -name "*.olean" | wc -l; }
echo "driver start $(date -u +%FT%TZ) host=$(hostname) cores=$(nproc) oleans=$(OLEANS)" >> $TL
for i in $(seq 1 12); do
  echo "attempt $i start $(date -u +%FT%TZ) oleans=$(OLEANS)" >> $TL
  $HOME/rh/sandbox/run.sh nonet "bash /home/ubuntu/full-build-inner.sh" >> $LOG 2>&1 < /dev/null
  RC=$?
  echo "attempt $i exit=$RC $(date -u +%FT%TZ) oleans=$(OLEANS) disk_free=$(df -h / | awk "NR==2{print \$4}")" >> $TL
  [ $RC -eq 0 ] && { echo "BUILD DONE $(date -u +%FT%TZ)" >> $TL; exit 0; }
  [ $RC -eq 99 ] && { echo "ABORT: network reachable" >> $TL; exit 99; }
  sleep 30
done
echo "GAVE UP after 12 attempts" >> $TL; exit 1
