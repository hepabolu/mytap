#!/bin/bash

# Installation script for MyTAP


SQLHOST=localhost;
SQLPORT=3306;

while [[ "$#" > 0 ]]; do
    case $1 in
	-u|--user)
	    SQLUSER="$2";
	    shift
	    ;;
	-p|--password)
	    SQLPASS="$2"
	    shift
	    ;;
	-h|--host)
	    SQLHOST="$2"
	    shift
	    ;;
	-P|--port)
	    SQLPORT="$2"
	    shift
	    ;;
	-t|--test)
	    WITHTEST="YES"
	    shift
	    ;;
	-h|--help)
	    cat << EOF
Usage:
 install.sh [options]

Options:
 -u, --user           MySQL username
 -p, --password       MySQL password
 -P, --port           MySQL port
 -h, --host           MySQL host
 -t, --test           Run the test suite when the install is completed
EOF
	   exit 1 
	   ;;
	 *)     
	   exit 1
	   ;;
    esac;
    shift;
done


MYSQLOPTS="--disable-pager --batch --raw --skip-column-names --unbuffered"

if [[ $SQLUSER != '' ]] && [[ $SQLPASS != '' ]]; then
    MYSQLOPTS="$MYSQLOPTS -u$SQLUSER -p$SQLPASS";
    CMD="--user $SQLUSER --password = $SQLPASS";
fi

if [[ $SQLHOST != 'localhost' ]]; then
   MYSQLOPTS="$MYSQLOPTS --host $SQLHOST";
   CMD="$CMD --host $SQLHOST";
fi

if [[ $SQLPORT != '3306' ]]; then
  MYSQLOPTS="$MYSQLOPTS --port $SQLPORT"
  CMD="$CMD --port $SQLPORT"
fi

if [[ $FILTER == '' ]]; then
  FILTER=0
fi

MYVER1=`mysql $MYSQLOPTS --execute "SELECT @@global.version" | awk -F'-' '{print $1}' | awk -F'.' '{print $1 * 100000 }'`;
MYVER2=`mysql $MYSQLOPTS --execute "SELECT @@global.version" | awk -F'-' '{print $1}' | awk -F'.' '{print $2 * 1000 }'`;
MYVER3=`mysql $MYSQLOPTS --execute "SELECT @@global.version" | awk -F'-' '{print $1}' | awk -F'.' '{print $3}'`;


MYVER=$(($MYVER1 + $MYVER2 + $MYVER3));

# import the full package before running the tests
# you can't use a wildcard with the source command so all version specific files need
# to be separately listed

echo "============= installing myTAP ============="
echo "Importing myTAP base"
mysql $MYSQLOPTS --execute 'source ./mytap.sql';
mysql $MYSQLOPTS --execute 'source ./mytap-global.sql';

if [[ $MYVER -gt 506000 ]]; then
    echo "Importing Version 5.6 patches";
    mysql $MYSQLOPTS --execute 'source ./mytap-table-56.sql';
fi

if [[ $MYVER -gt 507000 ]]; then
    echo "Importing Version 5.7 patches";
    mysql $MYSQLOPTS --execute 'source ./mytap-table-57.sql';
fi

if [[ $MYVER -gt 507006 ]]; then
    echo "Importing Version 5.7.6 patches";
    mysql $MYSQLOPTS --execute 'source ./mytap-global-57.sql';
fi

if [[ $MYVER -gt 800000 ]]; then
    echo "Importing Version 8.0 patches";
    mysql $MYSQLOPTS --execute 'source ./mytap-table-80.sql';
fi

if [[ $WITHTEST == 'YES' ]]; then
    echo "Run full test suite"
    CMD="./runtests.sh $CMD";
    exec $CMD;
fi

echo "Finished"
