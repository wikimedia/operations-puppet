# == Class: puppetmaster::gitsync
#
# Sync local operations/puppet.git checkout with upstream.
# Meant for use with local puppetmasters.
class puppetmaster::gitsync{

    file { '/usr/local/bin/git-sync-upstream':
        ensure  => present,
        source  => 'puppet:///modules/puppetmaster/git-sync-upstream',
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
    }

    cron { 'rebase_operations_puppet':
        ensure  => present,
        user    => 'root',
        minute  => '*/10',
        command => '/usr/local/bin/git-sync-upstream >>/var/log/git-sync-upstream.log 2>&1',
        require => File['/usr/local/bin/git-sync-upstream'],
    }

    file { '/etc/logrotate.d/git-sync-upstream':
        ensure  => present,
        source  => 'puppet:///modules/puppetmaster/git-sync-upstream.logrotate',
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
    }
}
