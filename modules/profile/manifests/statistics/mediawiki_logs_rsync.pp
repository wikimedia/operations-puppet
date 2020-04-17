# == Class profile::statistics::mediawiki_logs_rsync
#
class profile::statistics::mediawiki_logs_rsync {

    $hosts_with_mediawiki_logs_rsync = ['stat1007']

    if $::hostname in $hosts_with_mediawiki_logs_rsync {
        class { 'statistics::rsync::mediawiki': }
    }
}