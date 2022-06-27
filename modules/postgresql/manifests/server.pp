# Class: postgresql::server
#
# This class installs postgresql packages, standard configuration
#
# Parameters:
#   pgversion
#       Defaults to 9.6 in Debian Stretch
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
    Wmflib::Ensure             $ensure                      = 'present',
    Array                      $includes                    = [],
    String                     $listen_addresses            = '*',
    Stdlib::Port               $port                        = 5432,
    Stdlib::Unixpath           $root_dir                    = '/var/lib/postgresql',
    Boolean                    $use_ssl                     = false,
    String                     $log_line_prefix             = '%t ',
    Optional[Integer[250]]     $log_min_duration_statement  = undef,
    Optional[Integer]          $log_autovacuum_min_duration = undef,
    Optional[Numeric]          $pgversion                   = undef,
    Optional[Stdlib::Unixpath] $ssldir                      = undef,
) {

    case debian::codename() {
        'stretch': {
            $_pgtop = 'ptop'
            $_pgversion_default = 9.6
        }
        'buster': {
            $_pgtop = 'pgtop'
            $_pgversion_default = 11
        }
        'bullseye': {
            $_pgtop = 'pgtop'
            $_pgversion_default = 13
        }
        default: {
            fail("${title} not supported by: ${debian::codename()})")
        }
    }
    $_pgversion = $pgversion ? {
        undef   => $_pgversion_default,
        default => $pgversion,
    }


    package { [
        "postgresql-${_pgversion}",
        "postgresql-${_pgversion}-debversion",
        "postgresql-client-${_pgversion}",
        'libdbi-perl',
        'libdbd-pg-perl',
        'check-postgres',
        $_pgtop,
    ]:
        ensure => $ensure,
    }

    # The contrib package got dropped from Postgres in 10, it's only a virtual
    # package and not needed starting with Buster
    if debian::codename::lt('buster') {
        package { "postgresql-contrib-${_pgversion}":
            ensure => $ensure,
        }
    }

    class { 'postgresql::dirs':
        ensure    => $ensure,
        pgversion => $_pgversion,
        root_dir  => $root_dir,
    }

    $data_dir = "${root_dir}/${_pgversion}/main"

    $service_name = 'postgresql'

    exec { 'pgreload':
        command     => "/usr/bin/pg_ctlcluster ${_pgversion} main reload",
        user        => 'postgres',
        refreshonly => true,
    }

    if $use_ssl {
        file { "/etc/postgresql/${_pgversion}/main/ssl.conf":
            ensure  => $ensure,
            source  => 'puppet:///modules/postgresql/ssl.conf',
            owner   => 'root',
            group   => 'root',
            mode    => '0444',
            require => Puppet::Expose_agent_certs['/etc/postgresql'],
            before  => Service[$service_name],
        }

        # TODO: consider using profile::pki::get_cert
        puppet::expose_agent_certs { '/etc/postgresql':
            ensure          => $ensure,
            provide_private => true,
            user            => 'postgres',
            group           => 'postgres',
            ssldir          => $ssldir,
        }
    }

    service { $service_name:
        ensure  => stdlib::ensure($ensure, 'service'),
    }

    file { "/etc/postgresql/${_pgversion}/main/postgresql.conf":
        ensure  => $ensure,
        content => template('postgresql/postgresql.conf.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
    }
}
