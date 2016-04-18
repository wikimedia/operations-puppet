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

    include gridengine::admin_host
    include gridengine::submit_host
    include toollabs::dev_environ
    include toollabs::exec_environ

    if $::operatingsystem == 'Ubuntu' {
        package { 'cgroup-bin':
            ensure => present,
        }
    }

    package { 'toollabs-webservice':
        ensure => latest,
    }

    package { 'mosh':
        ensure => present,
    }

    motd::script { 'bastion-banner':
        ensure => present,
        source => "puppet:///modules/toollabs/40-${::labsproject}-bastion-banner",
    }

    file {'/etc/security/limits.conf':
        ensure => file,
        mode   => '0444',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/toollabs/limits.conf',
    }

    file { '/etc/ssh/ssh_config':
        ensure => file,
        mode   => '0444',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/toollabs/submithost-ssh_config',
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
