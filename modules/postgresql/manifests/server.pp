# Class: postgresql::server
#
# This class installs postgresql packages, standard configuration
#
# Parameters:
#   pgversion
#       Defaults to 9.1. Valid values 8.4, 9.1 in Ubuntu Precise,
#       9.3 in Ubuntu Trusty, and 9.4 in Debian Jessie.
#   ensure
#       Defaults to present
#   includes
#       An array of files that will be included in the config. It is
#       the caller's responsibility to provide these
#
# Actions:
#  Install/configure postgresql
#
# Requires:
#
# Sample Usage:
#  include postgresql::server
#
class postgresql::server(
    $pgversion = $::lsbdistcodename ? {
        jessie  => '9.4',
        trusty  => '9.3',
        default => '9.1',
    },
    $ensure='present',
    $includes=[],
    $listen_addresses='*',
    $port='5432',
    $datadir=undef,
) {
    package { [
            "postgresql-${pgversion}",
            "postgresql-${pgversion}-debversion",
            "postgresql-client-${pgversion}",
            'libdbi-perl',
            'libdbd-pg-perl',
        ]:
        ensure    => $ensure,
    }

    exec { 'pgreload':
        command     => "/usr/bin/pg_ctlcluster ${pgversion} main reload",
        user        => 'postgres',
        refreshonly => true,
    }

    service { 'postgresql':
        ensure  => ensure_service($ensure),
        require => Package["postgresql-${pgversion}"]
    }

    file { "/etc/postgresql/${pgversion}/main/postgresql.conf":
        ensure  => $ensure,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('postgresql/postgresql.conf.erb'),
    }

}
