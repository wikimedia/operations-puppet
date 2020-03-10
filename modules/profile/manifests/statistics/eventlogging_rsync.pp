# == Class profile::statistics::eventlogging_rsync
#
class profile::statistics::eventlogging_rsync {

    $hosts_with_eventlogging_rsync = ['stat1006', 'stat1007']

    if $::hostname in $hosts_with_eventlogging_rsync {
        class { 'statistics::rsync::eventlogging': }
    }
}