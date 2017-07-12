# == Class statistics
# Base wrapper class for stat servers.
# All stat servers should include this class.
#
# == Parameters
#   $servers        - list of statistics servers.
#                     These will be granted rsync read and
#                     write access between each other.
#   $working_path   - Base path for statistics data.
#                     Default: /srv
class statistics(
    $servers,
    $working_path = '/srv'
) {
    include ::statistics::user

    # set up rsync modules for copying files
    # on statistic servers in $working_path
    class { '::statistics::rsyncd':
        path        => $working_path,
        hosts_allow => $servers,
    }
}
