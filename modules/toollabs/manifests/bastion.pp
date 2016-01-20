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
            gridengine::admin_host,
            toollabs::exec_environ,
            toollabs::dev_environ

    file { '/etc/ssh/ssh_config':
        ensure => file,
        mode   => '0444',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/toollabs/submithost-ssh_config',
    }

    # webservice-new command
    package { 'toollabs-webservice':
        ensure => latest,
    }

    motd::script { 'bastion-banner':
        ensure => present,
        source => "puppet:///modules/toollabs/40-${::labsproject}-bastion-banner",
    }

    file { "${toollabs::store}/submithost-${::fqdn}":
        ensure  => file,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        require => File[$toollabs::store],
        content => "${::ipaddress}\n",
    }

    # Because it rocks
    package { 'mosh':
        ensure => present,
    }
    # Display tips.
    file { '/etc/profile.d/motd-tips.sh':
        ensure  => absent,
    }

    include ldap::role::config::labs
    $ldapconfig = $ldap::role::config::labs::ldapconfig

    $cron_host = hiera('active_cronrunner')
    file { '/usr/local/bin/crontab':
        ensure  => file,
        mode    => '0755',
        owner   => 'root',
        group   => 'root',
        content => template('toollabs/crontab.erb'),
    }
    file { '/usr/local/bin/killgridjobs.sh':
        ensure => file,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/toollabs/gridscripts/killgridjobs.sh',
    }
}
