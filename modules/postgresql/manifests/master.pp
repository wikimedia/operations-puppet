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
#       Defaults to 9.1. Valid values 8.4, 9.1 in Ubuntu
#   ensure
#       Defaults to present
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
                    ) {

    class { 'postgresql::server':
        pgversion => $pgversion,
        ensure    => $ensure,
        includes  => [ $includes, 'master.conf'],
    }

    Postgresql::User <<| tag == $master_server |>>

    file { "/etc/postgresql/${pgversion}/main/master.conf":
        ensure  => $ensure,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        source  => 'puppet:///modules/postgresql/master.conf',
        require => Class['postgresql::server'],
    }
}
