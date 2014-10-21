# Class: toollabs::bastion
#
# This role sets up an bastion/dev instance in the Tool Labs model.
#
# Parameters:
#
# Actions:
#
# Requires:
#
# Sample Usage:
#
class toollabs::bastion inherits toollabs {

    include gridengine::submit_host,
            toollabs::exec_environ,
            toollabs::dev_environ

    file { '/etc/ssh/ssh_config':
        ensure => file,
        mode   => '0444',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/toollabs/submithost-ssh_config',
    }

    file { '/etc/update-motd.d/40-bastion-banner':
        ensure => file,
        mode   => '0755',
        owner  => 'root',
        group  => 'root',
        source => "puppet:///modules/toollabs/40-${::instanceproject}-bastion-banner",
    }

    file { "${toollabs::store}/submithost-${::fqdn}":
        ensure  => file,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        require => File[$toollabs::store],
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

}
