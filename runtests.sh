#!/bin/bash

# shell script to run all tap tests

PASSW=$1

echo "============= updating tap ============="
mysql -u root --disable-pager --batch --raw --skip-column-names --unbuffered --password="$PASSW" --execute 'source ./mytap.sql'

echo "============= hastap ============="
mysql -u root --disable-pager --batch --raw --skip-column-names --unbuffered --password="$PASSW" --database tap --execute 'source tests/hastap.my'
echo "============= matching ============="
mysql -u root --disable-pager --batch --raw --skip-column-names --unbuffered --password="$PASSW" --database tap --execute 'source tests/matching.my'
echo "============= eq ============="
mysql -u root --disable-pager --batch --raw --skip-column-names --unbuffered --password="$PASSW" --database tap --execute 'source tests/eq.my'
echo "============= moretap ============="
mysql -u root --disable-pager --batch --raw --skip-column-names --unbuffered --password="$PASSW" --database tap --execute 'source tests/moretap.my'
echo "============= todotap ============="
mysql -u root --disable-pager --batch --raw --skip-column-names --unbuffered --password="$PASSW" --database tap --execute 'source tests/todotap.my'
echo "============= utils ============="
mysql -u root --disable-pager --batch --raw --skip-column-names --unbuffered --password="$PASSW" --database tap --execute 'source tests/utils.my'
echo "============= tabletap ============="
mysql -u root --disable-pager --batch --raw --skip-column-names --unbuffered --password="$PASSW" --database tap --execute 'source tests/tabletap.my'
echo "============= coltap ============="
mysql -u root --disable-pager --batch --raw --skip-column-names --unbuffered --password="$PASSW" --database tap --execute 'source tests/coltap.my'
echo "============= viewtap ============="
mysql -u root --disable-pager --batch --raw --skip-column-names --unbuffered --password="$PASSW" --database tap --execute 'source tests/viewtap.my'
