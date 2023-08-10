# SPDX-License-Identifier: Apache-2.0
# == define bigtop::mysql_jdbc
#
# Helper to deploy the mysql jar and custom symlinks
# where needed.
#
define bigtop::mysql_jdbc (
    String $link_path,
    Optional[Boolean] $use_mysql_jar = false,
) {
    $package_name = 'libmysql-java'
    $jar_path = $use_mysql_jar ? {
        true    => '/usr/share/java/mysql.jar',
        default => '/usr/share/java/mysql-connector-java.jar',
    }
    if !defined(Apt::Package_from_component['libmysql-java-component']) {
        apt::package_from_component { 'libmysql-java-component':
            component => 'component/libmysql-java',
            packages  => [$package_name],
        }
    }

    ensure_packages($package_name)
    file { $link_path:
        ensure  => 'link',
        target  => $jar_path,
        require => Package[$package_name],
    }
}
