# Class: toollabs::submit
#
# This role sets up an submit host instance in the Tool Labs model.
#
# Parameters:
#       gridmaster => FQDN of the gridengine master
#
# Actions:
#
# Requires:
#
# Sample Usage:
#
class toollabs::submit($gridmaster) inherits toollabs {
    include toollabs::exec_environ,
        toollabs::gridnode

    file { '/etc/ssh/ssh_config':
        ensure => file,
        mode   => '0444',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/toollabs/submithost-ssh_config',
    }

    class { 'gridengine::submit_host':
        gridmaster => $gridmaster,
    }

    class { 'toollabs::hba':
        store => $toollabs::store,
    }

    file { '/etc/update-motd.d/40-bastion-banner':
        ensure => file,
        mode   => '0755',
        owner  => 'root',
        group  => 'root',
        source => "puppet:///modules/toollabs/40-${::instanceproject}-submithost-banner",
    }

    file { "${toollabs::store}/submithost-${::fqdn}":
        ensure  => file,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        require => File[$toollabs::store],
        content => "${::ipaddress}\n",
    }

    package { 'misctools':
        ensure => latest,
    }
}
