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

    # Ensure /srv/log exists.
    file { '/srv/log':
        ensure => 'directory',
    }

    $working_path = '/srv'
}
