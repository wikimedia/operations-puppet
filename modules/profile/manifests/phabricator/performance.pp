# == Class: profile::phabricator::performance
#
# Set of sysctl network tuning parameters to improve Phabricator's performance
# under load.
#
class profile::phabricator::performance {
    sysctl::parameters { 'phabricator network tuning':
        values => {
            # Increase the number of ephemeral ports
            'net.ipv4.ip_local_port_range' => [ 4001, 65534 ],
            # This helps prevent TIME_WAIT issues for our $localip<->$dbproxy connections.
            'net.ipv4.tcp_tw_reuse'        => 1,
        }
    }
}