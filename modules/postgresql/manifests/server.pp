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
    $root_dir         = '/var/lib/postgresql',
) {
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

    $data_dir = "${root_dir}/${pgversion}/main"

    file {  [ $root_dir, "${root_dir}/${pgversion}" ] :
        ensure => ensure_directory($ensure),
        owner  => 'postgres',
        group  => 'postgres',
        mode   => '0755',
    }
    file { $data_dir:
        ensure => ensure_directory($ensure),
        owner  => 'postgres',
        group  => 'postgres',
        mode   => '0700',
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
        content => template('postgresql/postgresql.conf.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
    }
}
