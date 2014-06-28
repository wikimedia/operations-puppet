# Class: toollabs::bastion
#
# This role sets up an bastion/dev instance in the Tool Labs model.
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
class toollabs::bastion($gridmaster) inherits toollabs {
    include toollabs::exec_environ,
        toollabs::dev_environ,
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

    file { '/etc/update-motd.d/40-bastion-banner':
        ensure => file,
        mode   => '0755',
        owner  => 'root',
        group  => 'root',
        source => "puppet:///modules/toollabs/40-${instanceproject}-bastion-banner",
    }

    file { "${store}/submithost-${::fqdn}":
        ensure  => file,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        require => File[$store],
        content => "${::ipaddress}\n",
    }

    # Display tips.
    package { 'grep':
        ensure => present,
    }

    file { '/etc/profile.d/motd-tips.sh':
        ensure  => file,
        mode    => '0555',
        owner   => 'root',
        group   => 'root',
        source  => 'puppet:///modules/toollabs/motd-tips.sh',
        require => Package['grep'],
    }

    package { 'misctools':
        ensure => latest,
    }

    file { '/usr/local/bin/xcrontab':
        ensure => file,
        mode   => '0755',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/toollabs/crontab',
    }

    # Collect active users metric with diamond
    package { 'python-utmp':
        ensure => present
    }

    diamond::collector{ 'Users':
        require => Package['python-utmp']
    }
}
