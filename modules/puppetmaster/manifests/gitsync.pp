# == Class: puppetmaster::gitsync
#
# Sync local operations/puppet.git checkout with upstream.
# Meant for use with local puppetmasters.
# == Parameters
#
# [*repo_path*]
#   The path to the operations/puppet.git repository
# [*statsd_host*]
#   The host to send stats about cherry-picked commits to
class puppetmaster::gitsync(
    $repo_path = '/var/lib/git/operations/puppet',
    $statsd_host = 'labmon1001.eqiad.wmnet',
){

    file { '/usr/local/bin/git-sync-upstream':
        ensure  => present,
        content => template('puppetmaster/git-sync-upstream.erb'),
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
        mode    => '0444',
        require => Cron['rebase_operations_puppet'],
    }
}
