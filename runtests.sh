#!/bin/bash

# shell script to run all tap tests

USER=$1
PASSW=$2

MYSLOPTS="-u $USER -p$PASSW --disable-pager --batch --raw --skip-column-names --unbuffered"

echo "============= updating tap ============="
mysql $MYSLOPTS --execute 'source ./mytap.mysql'

echo "============= hastap ============="
mysql $MYSLOPTS --database tap --execute 'source tests/hastap.my'
echo "============= matching ============="
mysql $MYSLOPTS --database tap --execute 'source tests/matching.my'
echo "============= eq ============="
mysql $MYSLOPTS --database tap --execute 'source tests/eq.my'
echo "============= moretap ============="
mysql $MYSLOPTS --database tap --execute 'source tests/moretap.my'
echo "============= todotap ============="
mysql $MYSLOPTS --database tap --execute 'source tests/todotap.my'
echo "============= utils ============="
mysql $MYSLOPTS --database tap --execute 'source tests/utils.my'
echo "============= viewtap ============="
mysql $MYSLOPTS --database tap --execute 'source tests/viewtap.my'
echo "============= coltap ============="
mysql $MYSLOPTS --database tap --execute 'source tests/coltap.my'
echo "============= routinestap ========"
mysql $MYSLOPTS --database tap --execute 'source tests/routinestap.my'
