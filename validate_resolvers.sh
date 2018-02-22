#!/bin/bash
#
# (C) 2018 copyright@mzpqnxow.com - See LICENSE in this repository
#
# Check a list of hosts for TCP or UDP DNS services
# Not terribly invasive since each host comes from a public list
# and only receives two packets (one on UDP/53, one on TCP/53)
#
# Use this for gathering sample data for analysis related to DNS
# Please don't use this for something nefarious, thanks.
#
#
LIST=resolver_candidates.lst
SWEEP_OUTFILE=$(mktemp)
UP_OUTFILE=up
OUTFILE=resolvers-confirmed-$(date +%Y-%m-%d).lst
PPS_RATE=2048
TEST_DOMAIN=google.com
HOST_OPTIONS="-t a -W 2"
# sudo setcap CAP_NET_RAW+ep /usr/bin/masscan to avoid usage of sudo
# Otherwise, fill this in with the path to sudo
SUDO=

rm -f $TCP_UP_OUTFILE $UDP_UP_OUTFILE

$SUDO masscan -iL "$LIST" -p U:53,53 -oG "$SWEEP_OUTFILE" --rate "$PPS_RATE"
grep ^Host "$SWEEP_OUTFILE" | grep "open/tcp" | cut -d ' ' -f 2 | sort -u > "${PROTOCOL}-${UP_OUTFILE}"

for PROTOCOL in udp tcp
do
    [[ "$PROTOCOL" -eq "udp" ]] && FLAG=no || FLAG=""
    grep ^Host "$SWEEP_OUTFILE" | grep "open/udp" | cut -d ' ' -f 2 | sort -u > "${PROTOCOL}-{UP_OUTFILE}"
    for OPEN_SERVER in $(cat "${PROTOCOL}-${UP_OUTFILE}")
    do
        echo -n "Try $OPEN_SERVER ..."
        # host $HOST_OPTIONS "$TEST_DOMAIN" "$OPEN_SERVER" 2>&1 1>/dev/null && echo "$OPEN_SERVER" >> ${PROTOCOL}-OUTFILE
        echo dig -t a +${FLAG}tcp $TEST_DOMAIN @$OPEN_SERVER 2>&1 1>/dev/null && echo "$OPEN_SERVER" >> ${PROTOCOL}-${OUTFILE}
        if [ "$?" -eq "0" ]; then
            echo " open !!"
        else
            echo " rejected !!"
        fi
    done
done
# echo "DONE: $(wc -l $OUTFILE | cut -d ' ' -f 1) servers responding to queries"
# rm -f $SWEEP_OUTFILE $UP_OUTFILE

