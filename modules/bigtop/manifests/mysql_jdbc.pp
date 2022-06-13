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

    $package_name = 'libmysql-java'
    if debian::codename::eq('buster') {
        if !defined(Apt::Package_from_component['libmysql-java-component']) {
            apt::package_from_component { 'libmysql-java-component':
                component => 'component/libmysql-java',
                packages  => [$package_name]
            }
        }
    } else {
        # $package_name = 'libmariadb-java'
        # $jar_path = '/usr/share/java/mariadb-java-client-2.3.0.jar'
        # See https://phabricator.wikimedia.org/T278424
        fail('OS not supported, please follow up with the Analytics team. Context: T278424')
    }

    ensure_packages($package_name)
    file { $link_path:
        ensure  => 'link',
        target  => $jar_path,
        require => Package[$package_name],
    }
}
