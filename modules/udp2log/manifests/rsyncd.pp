# == Class udp2log::rsyncd
#
# Sets up an rsync daemon to allow statistics
# and analytics servers to copy logs off of a
# udp2log host.
#
# Parameters:
#   $path        - path to udp2log logrotated archive directory
#   $allow_hosts - IP address of host from which to allow rsync
#
class udp2log::rsyncd(
        $path        = '/var/log/udp2log/archive',
        $hosts_allow = ['stat1007.eqiad.wmnet']
) {

    class { 'rsync::server':
        # We don't want rsyncs to saturate udp2log host NICs.
        # Limit to 500M / sec.
        rsync_opts => ['--bwlimit 512000'],
    }

    rsync::server::module { 'udp2log':
        comment     => 'udp2log log files',
        path        => $path,
        read_only   => 'yes',
        hosts_allow => $hosts_allow,
        auto_ferm   => true,
    }
}
