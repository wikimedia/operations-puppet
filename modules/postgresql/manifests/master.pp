# Class: postgresql::master
#
# This class installs the server in a master configuration
#
# Parameters:
#   master_server
#       An FQDN. Defaults to $::fqdn. Should be the same as in slaves configured with this module
#   includes
#       An array of files to be included by the main configuration
#   pgversion
#       Defaults to 9.1. Valid values 8.4, 9.1 in Ubuntu Precise
#   ensure
#       Defaults to present
#   max_wal_senders
#       Defaults to 3. Refer to postgresql documentation for its meaning
#   checkpoint_segments
#       Defaults to 64. Refer to postgresql documentation for its meaning
#   wal_keep_segments
#       Defaults to 128. Refer to postgresql documentation for its meaning
#   root_dir
#       See $postgresql::server::root_dir
#   use_ssl
#       Enable ssl
#
# Actions:
#  Install/configure postgresql as a master. Also create replication users
#
# Requires:
#
# Sample Usage:
#  include postgresql::master

class postgresql::master(
    $master_server=$::fqdn,
    $includes=[],
    $pgversion = $::lsbdistcodename ? {
        jessie  => '9.4',
        precise => '9.1',
        trusty  => '9.3',
    },
    $ensure='present',
    $max_wal_senders=3,
    $checkpoint_segments=64,
    $wal_keep_segments=128,
    $root_dir='/var/lib/postgresql',
    $use_ssl=false,
) {

    $data_dir = "${root_dir}/${pgversion}/main"

    class { 'postgresql::server':
        ensure    => $ensure,
        pgversion => $pgversion,
        includes  => [ $includes, 'master.conf'],
        root_dir  => $root_dir,
        use_ssl   => $use_ssl,
    }

    file { "/etc/postgresql/${pgversion}/main/master.conf":
        ensure  => $ensure,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('postgresql/master.conf.erb'),
        require => Class['postgresql::server'],
    }

    if $ensure == 'present' {
        exec { 'pg-initdb':
            command => "/usr/lib/postgresql/${pgversion}/bin/initdb -D ${data_dir}",
            user    => 'postgres',
            unless  => "/usr/bin/test -f ${data_dir}/PG_VERSION",
            require => Class['postgresql::server'],
        }
    }
}
