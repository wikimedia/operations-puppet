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
        'buster': {
            $_pgversion_default = 11
        }
        'bullseye': {
            $_pgversion_default = 13
        }
        'bookworm': {
            $_pgversion_default = 15
        }
        default: {
            fail("${title} not supported by: ${debian::codename()})")
        }
    }
    $_pgversion = $pgversion ? {
        undef   => $_pgversion_default,
        default => $pgversion,
    }

    $service_name = "postgresql@${_pgversion}-main.service"
    $data_dir = "${root_dir}/${_pgversion}/main"

    systemd::mask { $service_name:
        unless  => "/usr/bin/test -f ${data_dir}/PG_VERSION",
    }

    # Mask the service on package installation, since we are setting up
    # databases via puppet.
    Systemd::Mask[$service_name]
        -> Package["postgresql-${_pgversion}"]
        -> Service[$service_name]

    package { [
        "postgresql-${_pgversion}",
        "postgresql-${_pgversion}-debversion",
        "postgresql-client-${_pgversion}",
        'libdbi-perl',
        'libdbd-pg-perl',
        'check-postgres',
        'pgtop',
    ]:
        ensure => $ensure,
    }

    class { 'postgresql::dirs':
        ensure    => $ensure,
        pgversion => $_pgversion,
        root_dir  => $root_dir,
    }

    exec { 'pgreload':
        command     => "/usr/bin/systemctl reload ${service_name}",
        refreshonly => true,
        require     => Service[$service_name],
    }

    if $use_ssl {
        file { "/etc/postgresql/${_pgversion}/main/ssl.conf":
            ensure  => $ensure,
            source  => 'puppet:///modules/postgresql/ssl.conf',
            owner   => 'root',
            group   => 'root',
            mode    => '0444',
            require => [
                Puppet::Expose_agent_certs['/etc/postgresql'],
                Package["postgresql-${_pgversion}"],
            ],
            before  => Service[$service_name],
        }

        # TODO: consider using profile::pki::get_cert
        puppet::expose_agent_certs { '/etc/postgresql':
            ensure          => $ensure,
            provide_private => true,
            user            => 'postgres',
            group           => 'postgres',
            ssldir          => $ssldir,
            require         => Package["postgresql-${_pgversion}"],
        }
    }

    service { $service_name:
        ensure  => stdlib::ensure($ensure, 'service'),
        require => Package["postgresql-${_pgversion}"],
    }

    file { "/etc/postgresql/${_pgversion}/main/postgresql.conf":
        ensure  => $ensure,
        content => template('postgresql/postgresql.conf.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        require => Package["postgresql-${_pgversion}"],
    }
}
