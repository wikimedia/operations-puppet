# Class: postgresql::server
#
# This class installs postgresql packages, standard configuration
#
# Parameters:
#   pgversion
#       Defaults to 9.1 in Ubuntu Precise, 9.3 in Ubuntu Trusty,
#       and 9.4 in Debian Jessie. Ubuntu Precise may choose 8.4.
#       FIXME: Just use the unversioned package name and let apt
#       do the right thing.
#   ensure
#       Defaults to present
#   includes
#       An array of files that will be included in the config. It is
#       the caller's responsibility to provide these
#   root_dir
#       The root directory for postgresql data. The actual directory will be
#       "${root_dir}/${pgversion}/main".
#   use_ssl
#       Enable ssl
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
    $pgversion        = $::lsbdistcodename ? {
        'jessie'  => '9.4',
        'precise' => '9.1',
        'trusty'  => '9.3',
    },
    $ensure           = 'present',
    $includes         = [],
    $listen_addresses = '*',
    $port             = '5432',
    $root_dir         = '/var/lib/postgresql',
    $use_ssl          = false,
) {
    require ::postgresql::packages
    class { '::postgresql::dirs':
        ensure    => $ensure,
        pgversion => $pgversion,
        root_dir  => $root_dir,
    }

    $data_dir = "${root_dir}/${pgversion}/main"

    $service_name = $::lsbdistcodename ? {
        'jessie' => "postgresql@${pgversion}-main",
        default  => 'postgresql',
    }
    exec { 'pgreload':
        command     => "/usr/bin/pg_ctlcluster ${pgversion} main reload",
        user        => 'postgres',
        refreshonly => true,
    }

    if $use_ssl {
        file { "/etc/postgresql/${pgversion}/main/ssl.conf":
            ensure  => $ensure,
            source  => 'puppet:///modules/postgresql/ssl.conf',
            owner   => 'root',
            group   => 'root',
            mode    => '0444',
            require => Base::Expose_puppet_certs['/etc/postgresql'],
            before  => Service[$service_name],
        }

        ::base::expose_puppet_certs { '/etc/postgresql':
            ensure          => $ensure,
            provide_private => true,
            user            => 'postgres',
            group           => 'postgres',
        }
    }

    service { $service_name:
        ensure  => ensure_service($ensure),
    }

    file { "/etc/postgresql/${pgversion}/main/postgresql.conf":
        ensure  => $ensure,
        content => template('postgresql/postgresql.conf.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
    }
}
