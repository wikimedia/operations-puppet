# Class: toollabs::submit
#
# This role sets up an submit host instance in the Tool Labs model.
# (A host that can only be used to submit jobs; presently used by
# tools-submit which runs bigbrother and the gridwide cron.
#
# Parameters:
#
# Actions:
#
# Requires:
#
# Sample Usage:
#
class toollabs::submit inherits toollabs {

    include gridengine::submit_host,
            toollabs::hba

    file { '/etc/ssh/ssh_config':
        ensure => file,
        mode   => '0444',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/toollabs/submithost-ssh_config',
    }

    motd::script { 'submithost-banner':
        ensure => present,
        source => "puppet:///modules/toollabs/40-${::labsproject}-submithost-banner",
    }

    file { "${toollabs::store}/submithost-${::fqdn}":
        ensure  => file,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        require => File[$toollabs::store],
        content => "${::ipaddress}\n",
    }

    file { '/usr/local/bin/webservice2':
        ensure => present,
        source => 'puppet:///modules/toollabs/webservice2',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }

    # Backup crontabs! See https://phabricator.wikimedia.org/T95798
    file { '/data/project/.system/crontabs':
        ensure => directory,
        owner  => 'root',
        group  => "${::labsproject}.admin",
        mode   => '0770',
    }
    file { "/data/project/.system/crontabs/${::fqdn}":
        ensure  => directory,
        source  => '/var/spool/cron/crontabs',
        owner   => 'root',
        group   => "${::labsproject}.admin",
        mode    => '0440',
        recurse => true,
    }
}
