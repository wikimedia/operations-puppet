# SPDX-License-Identifier: Apache-2.0
# == define bigtop::mysql_jdbc
#
# Helper to deploy Mysql/Mariadb jars and custom symlinks
# where needed.
#
define bigtop::mysql_jdbc (
    String $link_path,
    Optional[Boolean] $use_mysql_jar = false,
) {
    $jar_path = $use_mysql_jar ? {
        true    => '/usr/share/java/mysql.jar',
        default => '/usr/share/java/mysql-connector-java.jar',
    }

    if debian::codename::eq('buster') {
        $package_name = 'libmysql-java'
        if !defined(Apt::Package_from_component['libmysql-java-component']) {
            apt::package_from_component { 'libmysql-java-component':
                component => 'component/libmysql-java',
                packages  => [$package_name]
            }
        }
    } else {
        # See T278424 and T329363#8609591
        # For the bullseye upgrade we are trying once more to use libmariadb-java with sqoop instead of the forward-ported libmysql-java
        $package_name = 'libmariadb-java'
        $jar_path = '/usr/share/java/mariadb-java-client.jar'
    }

    ensure_packages($package_name)
    file { $link_path:
        ensure  => 'link',
        target  => $jar_path,
        require => Package[$package_name],
    }
}
