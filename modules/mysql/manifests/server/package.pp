# This is handled by a separate class in case we want to just
# install the package and configure elsewhere.
class mysql::server::package (
    $package_name     = $mysql::params::server_package_name,
) inherits mysql::params {
    include mysql::server
    if $package_name =~ /mariadb/ {
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
        ensure  => $mysql::server::package_ensure,
        name    => $package_name,
        require => $package_source,
    }
}
