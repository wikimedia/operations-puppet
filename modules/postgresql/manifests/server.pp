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
        jessie  => '9.4',
        precise => '9.1',
        trusty  => '9.3',
    },
    $ensure           = 'present',
    $includes         = [],
    $listen_addresses = '*',
    $port             = '5432',
    $basedir          = undef,
    $datadir          = undef,
) {

    $final_basedir = $basedir ? {
        undef   => '/var/lib/postgresql',
        default => $base_dir,
    }

    $final_datadir = $datadir ? {
        undef   => "${final_basedir}/${pgversion}/main",
        default => $datadir,
    }

    package { [
        "postgresql-${pgversion}",
        "postgresql-${pgversion}-debversion",
        "postgresql-client-${pgversion}",
        'libdbi-perl',
        'libdbd-pg-perl',
        'ptop',
    ]:
        ensure => $ensure,
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

    # There is no way to guess what directory hierarchy needs to be created if
    # it is not the default. So we create it only if $datadir is undef.
    if $datadir == undef {
        file { [
          $final_basedir,
          "${final_basedir}/${pgversion}",
        ]:
            ensure => directory,
            owner  => 'postgres',
            group  => 'postgres',
            mode   => '0755',
        }
        file { $datadir:
            ensure => directory,
            owner  => 'postgres',
            group  => 'postgres',
            mode   => '0700',
        }
    }

    file { "/etc/postgresql/${pgversion}/main/postgresql.conf":
        ensure  => $ensure,
        content => template('postgresql/postgresql.conf.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
    }
}
