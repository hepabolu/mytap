#!/bin/bash

# shell script to run all tap tests

USER=$1
PASSW=$2

# MYSLOPTS="-u $USER -p$PASSW --disable-pager --batch --raw --skip-column-names --unbuffered"
MYSLOPTS=" --disable-pager --batch --raw --skip-column-names --unbuffered"

echo "============= updating tap ============="
mysql $MYSLOPTS --execute 'source ./mytap.sql'


# echo "============= hastap ============="
# mysql $MYSLOPTS --database tap --execute 'source tests/hastap.my'
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
# echo "============= viewtap ============="
# mysql $MYSLOPTS --database tap --execute 'source tests/viewtap.my'
# echo "============= coltap ============="
#mysql $MYSLOPTS --database tap --execute 'source tests/coltap.my'
# echo "============= routinestap ========"
#mysql $MYSLOPTS --database tap --execute 'source tests/routinestap.my'
# echo "============= triggertap ========"
#mysql $MYSLOPTS --database tap --execute 'source tests/triggertap.my'

echo "============= character sets ============"
mysql $MYSLOPTS --database tap --execute 'source tests/test-mytap-charset.sql'
echo "============= collations ============"
mysql $MYSLOPTS --database tap --execute 'source tests/test-mytap-collation.sql'
echo "============= columns ============"
mysql $MYSLOPTS --database tap --execute 'source tests/test-mytap-column.sql'
echo "============= cconstraints ============"
mysql $MYSLOPTS --database tap --execute 'source tests/test-mytap-constraint.sql'
echo "============= engines ============"
mysql $MYSLOPTS --database tap --execute 'source tests/test-mytap-engine.sql'
echo "============= events ============"
mysql $MYSLOPTS --database tap --execute 'source tests/test-mytap-event.sql'
echo "============= indexes ============"
mysql $MYSLOPTS --database tap --execute 'source tests/test-mytap-index.sql'
echo "============= partitions ============"
mysql $MYSLOPTS --database tap --execute 'source tests/test-mytap-partition.sql'
echo "============= routines ============"
mysql $MYSLOPTS --database tap --execute 'source tests/test-mytap-routines.sql'
echo "============= schemas ============"
mysql $MYSLOPTS --database tap --execute 'source tests/test-mytap-schemata.sql'
echo "============= tables ============"
mysql $MYSLOPTS --database tap --execute 'source tests/test-mytap-table.sql'
echo "============= triggers ============"
mysql $MYSLOPTS --database tap --execute 'source tests/test-mytap-trigger.sql'
echo "============= users ============"
mysql $MYSLOPTS --database tap --execute 'source tests/test-mytap-user.sql'
echo "============= views ============"
mysql $MYSLOPTS --database tap --execute 'source tests/test-mytap-view.sql'
