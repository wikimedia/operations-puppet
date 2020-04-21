# == Class profile::statistics::eventlogging_rsync
#
class profile::statistics::eventlogging_rsync (
    $hosts_with_rsync = lookup('profile::statistics::eventlogging_rsync::hosts_with_rsync')
) {

    if $::hostname in $hosts_with_rsync {
        class { 'statistics::rsync::eventlogging': }
    }
}