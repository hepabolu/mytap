#!/bin/bash

# shell script to run all tap tests

if (( $# < 2 )); then
  echo ""
  echo "$0 username password [--filter hastap|matching|eq|moretap|todotap|utils|viewtap|coltap|routinestap|triggertap]"
  echo ""
  exit 0
fi


MYSLOPTS="-u $USER -p$PASSW --disable-pager --batch --raw --skip-column-names --unbuffered"

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

if [[ $FILTER == 0 ]] || [[ $FILTER =~ "charset" ]]; then
  echo "============= character sets ============"
  mysql $MYSLOPTS --database tap --execute 'source tests/test-mytap-charset.sql'
fi

if [[ $FILTER == 0 ]] || [[ $FILTER =~ "collation" ]]; then
  echo "============= collations ============"
  mysql $MYSLOPTS --database tap --execute 'source tests/test-mytap-collation.sql'
fi

if [[ $FILTER == 0 ]] || [[ $FILTER =~ "column" ]]; then
  echo "============= columns ============"
  mysql $MYSLOPTS --database tap --execute 'source tests/test-mytap-column.sql'
fi

if [[ $FILTER == 0 ]] || [[ $FILTER =~ "constraint" ]]; then
  echo "============= cconstraints ============"
  mysql $MYSLOPTS --database tap --execute 'source tests/test-mytap-constraint.sql'
fi

if [[ $FILTER == 0 ]] || [[ $FILTER =~ "engine" ]]; then
  echo "============= engines ============"
  mysql $MYSLOPTS --database tap --execute 'source tests/test-mytap-engine.sql'
fi

if [[ $FILTER == 0 ]] || [[ $FILTER =~ "event" ]]; then
  echo "============= events ============"
  mysql $MYSLOPTS --database tap --execute 'source tests/test-mytap-event.sql'
fi

if [[ $FILTER == 0 ]] || [[ $FILTER =~ "index" ]]; then
  echo "============= indexes ============"
  mysql $MYSLOPTS --database tap --execute 'source tests/test-mytap-index.sql'
fi

if [[ $FILTER == 0 ]] || [[ $FILTER =~ "utils" ]]; then
  echo "============= partitions ============"
  mysql $MYSLOPTS --database tap --execute 'source tests/test-mytap-partition.sql'
fi

if [[ $FILTER == 0 ]] || [[ $FILTER =~ "routines" ]]; then
  echo "============= routines ============"
  mysql $MYSLOPTS --database tap --execute 'source tests/test-mytap-routines.sql'
fi

if [[ $FILTER == 0 ]] || [[ $FILTER =~ "schemata" ]]; then
  echo "============= schemas ============"
  mysql $MYSLOPTS --database tap --execute 'source tests/test-mytap-schemata.sql'
fi

if [[ $FILTER == 0 ]] || [[ $FILTER =~ "table" ]]; then
  echo "============= tables ============"
  mysql $MYSLOPTS --database tap --execute 'source tests/test-mytap-table.sql'
fi

if [[ $FILTER == 0 ]] || [[ $FILTER =~ "trigger" ]]; then
  echo "============= triggers ============"
  mysql $MYSLOPTS --database tap --execute 'source tests/test-mytap-trigger.sql'
fi

if [[ $FILTER == 0 ]] || [[ $FILTER =~ "user" ]]; then
  echo "============= users ============"
  mysql $MYSLOPTS --database tap --execute 'source tests/test-mytap-user.sql'
fi

if [[ $FILTER == 0 ]] || [[ $FILTER =~ "view" ]]; then
  echo "============= views ============"
  mysql $MYSLOPTS --database tap --execute 'source tests/test-mytap-view.sql'
fi

