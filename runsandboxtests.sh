#!/bin/bash
#
# Run tests against the various sandboxed MySQL servers


USER=msandbox
PW=msandbox
HOST=127.0.0.1

PORT55=3306
PORT56=5636
PORT57=5718
PORT80=8001

MYSQLOPTS="-h $HOST -u $USER -p$PW"

# ==== MySQL 5.5

echo "============= updating tap in 5.5 ============="
mysql $MYSQLOPTS --port=$PORT55 --execute 'source ./mytap.sql'

myprove/bin/my_prove tests/* -h $HOST -P $PORT55 -u $USER -p $PW

# ==== MySQL 5.6

echo "============= updating tap in 5.6 ============="
mysql $MYSQLOPTS --port=$PORT56 --execute 'source ./mytap.sql'

myprove/bin/my_prove tests/* -h $HOST -P $PORT56 -u $USER -p $PW

# ==== MySQL 5.7

echo "============= updating tap in 5.7 ============="
mysql $MYSQLOPTS --port=$PORT57 --execute 'source ./mytap.sql'

myprove/bin/my_prove tests/* -h $HOST -P $PORT57 -u $USER -p $PW

# ==== MySQL 8.0

# echo "============= updating tap in 8.0 ============="
# mysql $MYSQLOPTS --port=$PORT80 --execute 'source ./mytap.sql'

# myprove/bin/my_prove tests/* -h $HOST -P $PORT80 -u $USER -p $PW

