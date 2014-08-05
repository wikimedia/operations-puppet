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
    $pgversion='9.1',
    $ensure='present',
    $max_wal_senders=3,
    $checkpoint_segments=64,
    $wal_keep_segments=128
    $datadir=undef,
    ) {

    class { 'postgresql::server':
        pgversion => $pgversion,
        ensure    => $ensure,
        includes  => [ $includes, 'master.conf'],
        datadir   => $datadir,
    }

    file { "/etc/postgresql/${pgversion}/main/master.conf":
        ensure  => $ensure,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('postgresql/master.conf.erb'),
        require => Class['postgresql::server'],
    }
}
