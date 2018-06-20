#!/bin/bash
#
# (C) 2018 copyright@mzpqnxow.com - See LICENSE in this repository
#
# Check a list of hosts for TCP or UDP DNS services
# Not terribly invasive since each host comes from a public list
# and only receives two packets (one on UDP/53, one on TCP/53)
#
# Use this for gathering sample data for analysis related to DNS
# Please don't use this for something nefarious, thanks. This will
# send two TCP SYN packets to each host in the resolver_candidates.lst
# file.
#
# Dependencies for Debian/Ubuntu:
#  $ sudo apt-get install bind9utils build-essential clang libpcap-dev
#  $ git clone https://github.com/robertdavidgraham/masscan
#  $ cd masscan
#  $ make
#  $ sudo make install
#  $ sudo setcap CAP_NET_RAW+ep /usr/bin/masscan
#

LIST=resolver_candidates.lst
SWEEP_OUTFILE=$(mktemp)
UP_OUTFILE=up
OUTFILE=resolvers-confirmed-$(date +%Y-%m-%d).lst
PPS_RATE=2048
TEST_DOMAIN=google.com
TMPDIR=tmp
OUTDIR=output
TIMEOUT=2
# sudo setcap CAP_NET_RAW+ep /usr/bin/masscan to avoid usage of sudo
# Otherwise, fill this in with the path to sudo
SUDO=

$SUDO masscan -iL "$LIST" -p U:53,53 -oG "$SWEEP_OUTFILE" --rate "$PPS_RATE"
mkdir -p "${TMPDIR}"
rm -f "${TMPDIR}/{tcp,udp}-up"
mkdir -p "${OUTDIR}"
rm -f "${OUTDIR}/*"
for PROTOCOL in udp tcp
do
    PROTOCOL_OUTFILE="${TMPDIR}/${PROTOCOL}-${UP_OUTFILE}"
    [[ "$PROTOCOL" == "udp" ]] && FLAG=no
    rm -f "${PROTOCOL}-${OUTFILE}"
    grep ^Host "$SWEEP_OUTFILE" | grep "open/${PROTOCOL}" | cut -d ' ' -f 2 | sort -u > "${PROTOCOL_OUTFILE}"
    for OPEN_SERVER in $(cat "${PROTOCOL_OUTFILE}")
    do
        echo -n "Try $OPEN_SERVER via ${PROTOCOL} ..."
        dig -t a +time=${TIMEOUT} +${FLAG}tcp $TEST_DOMAIN @$OPEN_SERVER 2>&1 1>/dev/null && echo "$OPEN_SERVER" >> "${OUTDIR}/${PROTOCOL}-${OUTFILE}"
        if [ "$?" -eq "0" ]; then
            echo " open !!"
        else
            echo " rejected !!"
        fi
    done
done

echo
echo "--- Results ---"
for PROTOCOL in udp tcp
do
    echo "DONE: $(wc -l ${OUTDIR}/${PROTOCOL}-${OUTFILE} | cut -d ' ' -f 1) servers responding to queries via protocol ${PROTOCOL} !!"
    rm -f "$SWEEP_OUTFILE"
done
