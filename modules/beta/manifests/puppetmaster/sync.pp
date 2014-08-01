# == Class: beta::puppetmaster::sync
#
# Sync local operations/puppet.git checkout with upstream
#
class beta::puppetmaster::sync {

    file { '/usr/local/bin/git-sync-upstream':
        ensure => present,
        source => 'puppet:///modules/beta/git-sync-upstream',
        mode   => '0555',
    }

    cron { 'rebase_operations_puppet':
        ensure  => present,
        user    => 'root',
        minute  => 17,
        command => '/usr/local/bin/git-sync-upstream >>/var/log/git-sync-upstream.log 2>&1',
        require => File['/usr/local/bin/git-sync-upstream'],
    }

    file { '/etc/logrotate.d/git-sync-upstream':
        ensure  => present,
        source  => 'puppet:///modules/beta/git-sync-upstream.logrotate',
        mode    => '0444',
        require => Cron['rebase_operations_puppet'],
    }
}
