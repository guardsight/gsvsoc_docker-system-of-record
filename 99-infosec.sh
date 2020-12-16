# Copyright © 2020 GuardSight, Inc.
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
# SYNOPSIS: vsocGet|vsocDo <tab> <tab>
#
# DESCRIPTION: Helpers for gathering information from /data/logs/<HOSTS|CLASSES>
#
# AUTHOR: vsoc@guardsight.com
# 

# Not bash or zsh?
[ -n "$BASH_VERSION" -o -n "$ZSH_VERSION" ] || return 0

# Not an interactive shell?
[[ $- == *i* ]] || return 0


function vsocGetUniqWinHosts {
	LINES=1
	grep -oiE -m ${LINES} 'Hostname":"[a-zA-Z0-9_\.\-]*' /data/logs/HOSTS/*/$(date +%F)/* | sed -E 's/^.*\/HOSTS\/(.*)\/[0-9]{4}-[0-9]{2}-[0-9]{2}\/.*:[Hh]ostname":"/\1 : /' |  tr [[:upper:]] [[:lower:]] | sort -u
}

function vsocDoCompHosts {
	vsocGetUniqWinHosts | diff -u /var/tmp/current - | grep -E "^\+"
}

function vsocGetUniqWinHostsFmt {
	vsocGetUniqWinHosts | tr [[:upper:]] [[:lower:]] | sort -n -t . -k1,1 -k2,2 -k3,3 -k4,4 | nl -s ' : ' | column -t 
}


function vsocGetUniqWinHostsFmtAndUpdateCache {
	F=/var/tmp/vsocGetUniqWinHostsFmtAndUpdateCache.cache.txt
	vsocGetUniqWinHostsFmt | tee ${F}
	printf "\n\t**Updating ${F}**\n" > /dev/stderr
}

function vsocGetUniqWinHostsWithName {
	WITHNAME="$1"
	if [ -z ${WITHNAME} ]; then
		echo "Usage: ${FUNCNAME[0]} <name|ip>" > /dev/stderr
		echo "Ex: ${FUNCNAME[0]} acme-" > /dev/stderr
		echo "Ex: ${FUNCNAME[0]} 10.167.67" > /dev/stderr
		return 1;
	fi
	vsocGetUniqWinHostsFmt | grep -i "${WITHNAME}" | sed 's/\s//g; s/^[0-9]*//g; s/:/ : /g' | nl | column -t
}

function vsocGetUniqWinHostsCount {
	vsocGetUniqWinHosts | wc -l
}

function vsocGetAllHostsByIp {
	find /logs/HOSTS/*/$(date +%F)/ \! -path "*127.0.0.*"  | grep messages.log | cut -d '/' -f4 | sort -n -t . -k1,1 -k2,2 -k3,3 -k4,4
}

function vsocGetAllHostsByIpFmt {
	vsocGetAllHostsByIp | nl -s ' : ' | column -t
}

function vsocGetAllHostsCount {
	vsocGetAllHostsByIp  | wc -l
}

function jsonClipPreamble {
	cat - | sed -E 's/^.*\]?: ?\{/\{/'
}

function vsocDoJsonClipPreamble {
	jsonClipPreamble
}

function vsocDoJQconvertEventTimeLocal {
	# converts M$lop EvenTime epoch to local time and adds a field called EventTimeLocal
	# jq '. += { EventTimeLocal: (.EventTime | (tonumber|todate)) }'
	jq '. += { EventTimeLocal: (.EventTime | (tonumber|todate) | strptime("%Y-%m-%dT%H:%M:%SZ") | strflocaltime("%Y-%m-%dT%H:%M:%S%Z")) }'
}

function vsocDoBuildCLASSESWindows {
	CLASSES_WINDOWS_DIR=/logs/CLASSES/windows

	pushd ${CLASSES_WINDOWS_DIR} >/dev/null

	echo "Recalibrating ${CLASSES_WINDOWS_DIR}/ " >/dev/stderr
	mapfile WINHOSTS < <(vsocGetUniqWinHosts | cut -d ' ' -f1)
	for H in ${WINHOSTS[@]}; do
		ln -sf /logs/HOSTS/${H}; 
	done
	CLASSES_TOTAL=$(find /logs/CLASSES/windows -maxdepth 1 -type l | wc -l)			
	printf "\n%s\n" "{\"uniqwinhosts_total\": ${#WINHOSTS[@]}, \"classeswindows_total\": ${CLASSES_TOTAL}, \"uniqwinhosts_classeswindows_diff\": $(( ${#WINHOSTS[@]} - ${CLASSES_TOTAL} ))}" | jq .

	popd > /dev/null
}

function vsocDoBuildDNSNAMES {
	DNSNAMES_DIR=/logs/DNSNAMES

	pushd ${DNSNAMES_DIR} >/dev/null

	echo "Recalibrating ${DNSNAMES_DIR}/ " >/dev/stderr
	find /logs/HOSTS/ -maxdepth 1 -printf "%f\n" | egrep '^[0-9]' | grep -v 127.0.0.1 | while read i; do 
		d=$(dig +timeout=1 +short -x ${i});
		if [ $? -eq 0 ]; then 
			n=$(echo "${d}" | head -1 | tr [[:upper:]] [[:lower:]] | sed 's/.$//'); 
			if [ ! -z "${n}" ]; then
				printf "%s : %s\n" ${i} ${n}
				# ln -sf not working here / explicit rm first
				rm -f ${n} && ln -s /logs/HOSTS/${i} ${n}
			else
				printf "%s : %s\n" ${i} NO_NAME_FOUND > /dev/stderr
			fi
		fi;
	done

	popd > /dev/null
}

function vsocGetWinEventsById {
	EVENTID="$1"
        if [ -z ${EVENTID} ]; then
                echo "Usage: ${FUNCNAME[0]} <eventid>" > /dev/stderr
                echo "Ex: ${FUNCNAME[0]} 4625" > /dev/stderr
                return 1;
        fi

	# jq --argjson e "${EVENTID}" 'select( .EventID == $e ) /** doesn't always work */
	zgrep -E "EventID\":\s?${EVENTID}," /logs/CLASSES/windows/*/$(date +%F)/* | vsocDoJsonClipPreamble | vsocDoJQconvertEventTimeLocal
}

function vsocGetWinEventsByTimeLocal {
	TIME="$1" # 24H time - 1 or 12 or 12: or 13:4 or 13:45
        if [ -z ${TIME} ]; then
                echo "Usage: ${FUNCNAME[0]} <eventid>" > /dev/stderr
                echo "Ex: ${FUNCNAME[0]} 4625" > /dev/stderr
                return 1;
        fi
	echo "TODO: NOT FUNCTIONING YET" > /dev/stderr
	
	# jq --arg t "${TIME}" 'select(.EventTimeLocal | test("T$t"))'

}

function vsocGetEgressBytes {
	# grep 'Teardown TCP connection' /logs/CLASSES/firewalls/*/$(date +"%F")/* | grep 'Outside' | grep -v 'TCP FINs from Inside' | grep -v 'bytes 0 SYN Timeout' | cut -d' ' -f 11,13,15,17 | grep -E "Outside:[0-9\.]*/((443)|(80))" | cut -d' ' -f4 | sort -n
	grep 'Teardown TCP connection' /logs/CLASSES/firewalls/*/$(date +"%F")/* | grep 'Outside' | grep -v 'TCP FINs from Inside' | grep -v 'bytes 0 SYN Timeout' | grep -E "Outside:[0-9\.]*/[0-9]{2,4}"  | cut -d' ' -f 18 | egrep '[0-9]{7}' | sort -n
}

function vsocGetEgressBytesFmt {
	for c in $(vsocGetEgressBytes | tail -50); do	
		echo -n "${c} = " 
		numfmt --to=iec --suffix=B ${c}
	done
}

function vsocGetCompressionRatios {
	DAYS=30
	echo "Compression ratios for the last ${DAYS} days" > /dev/stderr
	# using xargs v. -exec to avoid subshell issue
	find /logs/HOSTS/ -name "*.gz" -mtime -30 | xargs gzip -l | awk '{print $3}' | grep -v ratio | tr -d '%' | ministat  -n
}


function vsocGetLoggingCountHistory {
	printf "\n====== $(date +%c) ======\n"; for D in {7..0}; do DATE=$(date +%F -d "${D} days ago"); printf "Assets logging count for %s" "${DATE} ($(date -d ${DATE} +%a)): "; find /logs/HOSTS/ -maxdepth 1 -type d -exec ls -d {}/${DATE} \; 2>/dev/null | wc -l; done
}

function vsocDoCheckVlans { 
	F=/var/tmp/vsocDoCheckVlans.vlan-list.txt;
	if [ ! -r ${F} ]; then 
		echo "Need ${F} in nnn.nnn.nnn.0/nn format separated by newlines to coninue" > /dev/stderr
		return 1;
	fi
	printf "\n====== $(date +%c) ======\n"; 
	sed 's/.0\/..//g' ${F}  | while read n; do echo ==== ${n} ====; vsocGetUniqWinHostsWithName ${n}; done;
}

