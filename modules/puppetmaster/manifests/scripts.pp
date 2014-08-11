# Class: puppetmaster::scripts
#
# This class installs some puppetmaster server side scripts required for the
# manifests
class puppetmaster::scripts {

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

    # Clear out reports older than 36 hours.
    cron { 'removeoldreports':
        ensure  => present,
        command => 'find /var/lib/puppet/reports -type f -mmin +2160 -delete',
        user    => puppet,
        hour    => [4,16],
        minute  => 27,
    }

    # Helper script to clean stored data about a server we're reimaging.
    file { '/usr/local/bin/wmf-reimage':
        ensure => 'present',
        owner  => 'root',
        group  => 'root',
        mode   => '0544',
        source => 'puppet://modules/puppetmaster/reimage.sh'
    }
}
