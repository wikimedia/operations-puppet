# This is handled by a separate class in case we want to just
# install the package and configure elsewhere.
class mysql::server::package (
    $package_name     = $mysql::params::server_package_name,
) {
    if $package_name =~ /mariadb/ and !os_version('debian >= stretch') {
        apt::repository { 'wikimedia-mariadb':
        uri        => 'http://apt.wikimedia.org/wikimedia',
        dist       => 'precise-wikimedia',
        components => 'mariadb',
        }
    }

    $package_source = $package_name ? {
        'mariadb-server-5.5' => Apt::Repository['wikimedia-mariadb'],
        default              => undef
    }

    package { 'mysql-server':
        # FIXME - top-scope var without namespace, will break in puppet 2.8
        # lint:ignore:variable_scope
        ensure  => $package_ensure,
        # lint:endignore
        name    => $package_name,
        require => $package_source,
    }
}
