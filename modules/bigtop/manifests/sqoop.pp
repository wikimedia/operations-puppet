# SPDX-License-Identifier: Apache-2.0
# == Class bigtop::sqoop
# Installs Sqoop 1
#
#
# NOTE: There is no sqoop-conf alternative defined,
# because there is not yet any sqoop specific
# configuartion handled by this puppet module.
#
class bigtop::sqoop {
    # Sqoop requires Hadoop configs installed.
    Class['bigtop::hadoop'] -> Class['bigtop::sqoop']

    package { 'sqoop':
        ensure => 'installed',
    }

    # Temporary workaround for https://issues.apache.org/jira/browse/BIGTOP-3508
    $sqoop_bin = @("SCRIPT"/$)
    #!/bin/bash

    # Autodetect JAVA_HOME if not defined
    . /usr/lib/bigtop-utils/bigtop-detect-javahome

    # BIGTOP-3508 - Prevent IllegalStateException on Debian systems
    SQOOP_JARS=`ls /var/lib/sqoop/*.jar 2>/dev/null`

    if [ -n "\${SQOOP_JARS}" ]; then
        export HADOOP_CLASSPATH=\$(JARS=(\${SQOOP_JARS}); IFS=:; echo "\${HADOOP_CLASSPATH}:\${JARS[*]}")
    fi

    export SQOOP_HOME=/usr/lib/sqoop
    exec /usr/lib/sqoop/bin/sqoop "$@"
    | SCRIPT

    file { '/usr/bin/sqoop':
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
        content => $sqoop_bin,
        require => Package['sqoop'],
    }

    # symlink the Mysql/Mariadb JDBC connector into /usr/lib/sqoop/lib
    # TODO: Can I create this symlink as mysql.jar?
    bigtop::mysql_jdbc { 'sqoop-mysql-connector':
        link_path => '/usr/lib/sqoop/lib/mysql-connector-java.jar',
        require   => Package['sqoop'],
    }
}