# == Class statistics
# Base wrapper class for stat servers.
# All stat servers should include this class.
#
# == Parameters
#   $servers        - list of statistics servers.
#                     These will be granted rsync read and
#                     write access between each other.
class statistics(
    $servers,
) {
    include ::statistics::user

    # TODO: remove statistics::working_path once stat1002 is gone: T152712
    $working_path = $::hostname ? {
        'stat1002' => '/a',
        default => '/srv',
    }

    # Ensure /srv/log exists.
    file { '/srv/log':
        ensure => 'directory',
    }

    # set up rsync modules for copying files
    # on statistic servers in $working_path
    class { '::statistics::rsyncd':
        path        => $working_path,
        hosts_allow => $servers,
    }
}
