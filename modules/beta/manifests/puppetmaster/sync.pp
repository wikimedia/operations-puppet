# == Class: beta::puppetmaster::sync
#
# Sync local operations/puppet.git checkout with upstream
#
class beta::puppetmaster::sync {

    file { '/user/local/bin/git-sync-upstream':
        ensure => present,
        source => 'puppet:///modules/beta/git-sync-upstream',
        mode   => '0555',
    }

    cron { 'rebase_operations_puppet':
        ensure  => present,
        user    => 'root',
        minute  => 17,
        command => '/usr/local/bin/git-sync-upstream 2>&1 >>/var/log/git-sync-upstream.log',
    }

    file { '/etc/logrotate.d/git-sync-upstream':
        ensure => present,
        source => 'puppet:///modules/beta/git-sync-upstream.logrotate',
        mode   => '0444',
    }
}
