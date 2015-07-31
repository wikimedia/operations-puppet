# == Class statistics
# Base wrapper class for stat servers.
# All stat servers should include this class.
#
# == Parameters
#   $rsync_hosts_allow - List of servers that are allowed to read
#                        from the rsync modules on this host.
#                        write access between each other.
#   $working_path      - Base path for statistics data.
#                        Default: /srv
class statistics(
    $rsync_hosts_allow,
    $working_path = '/srv'
) {
    include statistics::user

    file { $working_path:
        ensure => 'directory',
        owner  => 'root',
        group  => 'wikidev',
        mode   => '0775',
    }

    if $working_path == '/srv' {
        # symlink /a to /srv for backwards compatibility
        file { '/a':
            ensure => 'link',
            target => '/srv',
        }
    }

    # set up rsync modules for copying files
    # on statistic servers in $working_path
    class { 'statistics::rsyncd':
        path        => $working_path,
        hosts_allow => $rsync_hosts_allow,
    }
}
