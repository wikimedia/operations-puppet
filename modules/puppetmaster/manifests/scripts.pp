# Class: puppetmaster::scripts
#
# This class installs some puppetmaster server side scripts required for the
# manifests
#
# == Parameters
#
# [*keep_reports_minutes*]
#   Number of minutes to keep older reports for before deleting them
class puppetmaster::scripts(
    $keep_reports_minutes = 2160,
) {

    require puppetmaster::naggen2

    file {'/usr/local/bin/uuid-generator':
        ensure  => 'present',
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
        source  => 'puppet:///modules/puppetmaster/uuid-generator',
    }
    file {'/usr/local/bin/naggen':
        ensure  => 'absent',
    }
    file {'/usr/local/sbin/puppetstoredconfigclean.rb':
        ensure  => 'present',
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
        source  => 'puppet:///modules/puppetmaster/puppetstoredconfigclean.rb'
    }
    file{'/usr/local/bin/puppet-merge':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
        source  => 'puppet:///modules/puppetmaster/puppet-merge'
    }

    # Clear out older reports
    cron { 'removeoldreports':
        ensure  => present,
        command => "find /var/lib/puppet/reports -type f -mmin +$keep_reports_minutes -delete",
        user    => puppet,
        hour    => '*',
        minute  => 0,
    }

    # Helper script to clean stored data about a server we're reimaging.
    file { '/usr/local/bin/wmf-reimage':
        ensure => 'present',
        owner  => 'root',
        group  => 'root',
        mode   => '0544',
        source => 'puppet:///modules/puppetmaster/reimage.sh'
    }
}
