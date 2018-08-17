#!/bin/bash

#debug
set -x
#verbose
set -v

if [ ! -z "${DB}" ]; then
    # disable existing database server in case of accidential connection
    sudo service mysql stop

    docker pull ${DB}
    docker run -it --name=mysqld -d -e MYSQL_ALLOW_EMPTY_PASSWORD=yes -p 3306:3306 mysqld --default-authentication-plugin=mysql_native_password ${DB}
    sleep 10

    mysql() {
        docker exec mysqld --default-authentication-plugin=mysql_native_password mysql "${@}"
    }
    while :
    do
        sleep 5
        mysql -e 'select version()'
        if [ $? = 0 ]; then
            break
        fi
        echo "server logs"
        docker logs --tail 5 mysqld
    done

    mysql -e 'select VERSION()'

    if [ $DB == 'mysql:8.0' ]; then
	docker cp mysqld:/var/lib/mysql/public_key.pem "${HOME}"
	docker cp mysqld:/var/lib/mysql/ca.pem "${HOME}"
	docker cp mysqld:/var/lib/mysql/server-cert.pem "${HOME}"
	docker cp mysqld:/var/lib/mysql/client-key.pem "${HOME}"
	docker cp mysqld:/var/lib/mysql/client-cert.pem "${HOME}"
    fi
    # The following are all included in an attempt to get v8.0 access to work
    # by using mysql_native_password, it still refuses to work with
    # ERROR 2059 (HY000): Authentication plugin 'caching_sha2_password' cannot be loaded: /usr/lib/mysql/plugin/caching_sha2_password.so:
    # cannot open shared object file: No such file or directory
    # No matter they don't hinder operation for any other version
    # so I'm leaving them in
    mysql -u root -e "UPDATE mysql.user SET plugin = 'mysql_native_password'; FLUSH PRIVILEGES;"
    mysql -u root -e "CREATE USER 'mytap'@'%' IDENTIFIED WITH mysql_native_password; GRANT ALL on *.* TO 'mytap'@'%';"
    mysql -e 'SELECT user, host, plugin FROM mysql.user'
else
    cat ~/.my.cnf

    mysql -e 'select VERSION()'
fi
