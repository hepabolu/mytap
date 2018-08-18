#!/bin/bash

#debug
set -x
#verbose
set -v

if [ ! -z "${DB}" ]; then
    # disable existing database server in case of accidential connection
    sudo service mysql stop

    docker pull ${DB}
    docker run -it --name=mysqld -d -e MYSQL_ALLOW_EMPTY_PASSWORD=yes -p 3306:3306 ${DB}
    sleep 10

    mysql() {
        docker exec mysqld mysql "${@}"
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
      mysql -e 'SELECT user, host, plugin, authentication_string, password_expired, password_lifetime, account_locked FROM mysql.user'
      mysql -e "UPDATE mysql.user SET plugin = 'mysql_native_password' WHERE user != 'mysql.infoschema'";
      mysql -e "CREATE USER 'mytap'@'%' IDENTIFIED WITH mysql_native_password; GRANT ALL on *.* TO 'mytap'@'%'; FLUSH PRIVILEGES;"
      mysql -e 'SELECT user, host, plugin, authentication_string, password_expired, password_lifetime, account_locked FROM mysql.user'
    fi
else
    cat ~/.my.cnf

    mysql -e 'select VERSION()'
fi
