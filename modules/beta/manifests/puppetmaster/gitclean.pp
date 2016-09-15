# == Class: beta::puppetmaster::gitclean
#
# Sets up logrotate, cron, and bot arcrc with phab token to maintain cherrypicks
# on the beta puppetmaster
#
class beta::puppetmaster::gitclean {
    file { '/usr/local/bin/git-clean-puppetmaster':
        ensure => present,
        source => 'puppet:///modules/beta/puppetmaster/git-clean-puppetmaster.py',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }

    cron { 'clean_operations_puppet_patches':
        ensure  => present,
        user    => 'root',
        minute  => '0',
        command => '/usr/local/bin/git-clean-puppetmaster >>/var/log/git-clean-puppetmaster.log 2>&1',
        require => File['/usr/local/bin/git-clean-puppetmaster'],
    }

    logrotate::conf { 'git-clean-puppetmaster':
        source => 'puppet:///modules/beta/puppetmaster/git-clean-puppetmaster.logrotate',
    }

    file { '/root/beta-puppetmaster.arcrc':
        owner   => 'root',
        group   => 'root',
        mode    => '0400',
        content => secret('puppetmaster/beta-puppetmaster.arcrc'),
    }
}
