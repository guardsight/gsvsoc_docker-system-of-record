#!/bin/bash
#
# NAME - VSOC-logs-compress
#
# SYNOPSIS
# logs-compress
#
# DESCRIPTION
# Finds files, compresses them, makes them immutable, logs results
#
# AUTHOR
# vsoc@guardsight.com
#
# LICENSE
# GPLv3
# (c) GuardSight, Inc. 2019
#
PATH=/bin:/usr/bin:/sbin:/usr/sbin

G="/bin/gzip";
C="/usr/bin/chattr +i";
L="/usr/bin/logger -t $(basename $0)";

log(){
       msg=$(printf "CEF:0|GSVSOC|${2}|2.0|0|${3}|${1}|msg=${4}");
       logger "${msg}";

}

# find files named *.log with a specific modified time and skipping directories marked as $(date +%F) [today]
# compress them, make them immutable, log results
find -H /logs/HOSTS/ -mmin +1440 -name "*.log" -exec $G -f '{}' \; -exec $G -l '{}.gz' \; -print 2>&1 | grep -v compressed | while read f; do 
        stats=$(echo "${f}" | grep '%'); 
        echo "$f" | grep -q ' '; 
        if [ "$f" == "$stats" ]; then
                n=$(echo $stats | awk '{print $NF}'); b=$(basename $n); s=$(echo $stats | sed 's/%/%%/' | awk '{$NF=""; print $0}');
                log "3" "$(basename $0)" "gzip" "compress successful for: ${n}: ${s}"
                $C "$n.gz"  2>&1 | $L
                if [ $? -eq 0 ]; then
                        log "7" "$(basename $0)" "chattr" "immutable attribute change successful for: ${n}.gz"
                else
                        log "7" "$(basename $0)" "chattr" "immutable attribute change failed for: ${n}.gz" 
                fi
        else
                echo "$f" | grep -q ' '
                if [ $? -eq 0 ]; then
                        log "7" "$(basename $0)" "gzip" "compress failed for: ${f}"
                fi
        fi
done

exit 0;
