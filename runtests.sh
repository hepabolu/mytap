#!/bin/bash

# shell script to run all tap tests

if (( $# < 2 )); then
  echo ""
  echo "$0 username password [--filter hastap|matching|eq|moretap|todotap|utils|viewtap|coltap|routinestap|triggertap]"
  echo ""
  exit 0
fi

USER="$1"; shift
PASSW="$1"; shift

# find out if we want to filter to a specific set
FILTER="$@"

if [[ ${FILTER:0:8} = "--filter" ]]; then
  # strip the --filter prefix
  FILTER=${FILTER:8}

  # reset to everything when the filter is empty
  if [[ "$FILTER" == "" ]]; then
    FILTER=0
  fi
else
  # no filtering
  FILTER=0
fi

MYSLOPTS="-h 127.0.0.1 -u $USER -p$PASSW --disable-pager --batch --raw --skip-column-names --unbuffered"

echo "============= updating tap ============="
mysql $MYSLOPTS --execute 'source ./mytap.sql'

if [[ $FILTER != 0 ]]; then
  echo "============= filtering ============="
  echo "$FILTER"
fi

if [[ $FILTER == 0 ]] || [[ $FILTER =~ "hastap" ]]; then
  echo "============= hastap ============="
  mysql $MYSLOPTS --database tap --execute 'source tests/hastap.my'
fi

if [[ $FILTER == 0 ]] || [[ $FILTER =~ "matching" ]]; then
  echo "============= matching ============="
  mysql $MYSLOPTS --database tap --execute 'source tests/matching.my'
fi

if [[ $FILTER == 0 ]] || [[ $FILTER =~ "eq" ]]; then
echo "============= eq ============="
mysql $MYSLOPTS --database tap --execute 'source tests/eq.my'
fi

if [[ $FILTER == 0 ]] || [[ $FILTER =~ "moretap" ]]; then
echo "============= moretap ============="
mysql $MYSLOPTS --database tap --execute 'source tests/moretap.my'
fi

if [[ $FILTER == 0 ]] || [[ $FILTER =~ "todotap" ]]; then
echo "============= todotap ============="
mysql $MYSLOPTS --database tap --execute 'source tests/todotap.my'
fi

if [[ $FILTER == 0 ]] || [[ $FILTER =~ "utils" ]]; then
echo "============= utils ============="
mysql $MYSLOPTS --database tap --execute 'source tests/utils.my'
fi

if [[ $FILTER == 0 ]] || [[ $FILTER =~ "viewtap" ]]; then
echo "============= viewtap ============="
mysql $MYSLOPTS --database tap --execute 'source tests/viewtap.my'
fi

if [[ $FILTER == 0 ]] || [[ $FILTER =~ "coltap" ]]; then
echo "============= coltap ============="
mysql $MYSLOPTS --database tap --execute 'source tests/coltap.my'
fi

if [[ $FILTER == 0 ]] || [[ $FILTER =~ "routinestap" ]]; then
echo "============= routinestap ========"
mysql $MYSLOPTS --database tap --execute 'source tests/routinestap.my'
fi

if [[ $FILTER == 0 ]] || [[ $FILTER =~ "triggertap" ]]; then
echo "============= triggertap ========"
mysql $MYSLOPTS --database tap --execute 'source tests/triggertap.my'
fi
