# Workaround NAT traversal issue when a beta cluster instance attempt to
# connect to a beta public IP. The NAT would get the packet loss, instead
# transparently destination IP of outgoing packets to point directly to the
# private IP instance instead of the public IP.
#
# FIXME should probably be applied by default on ALL beta cluster instances.
#
# References:
#
# RT #4824   - https://rt.wikimedia.org/Ticket/Display.html?id=4824
# bug #45868 - https://bugzilla.wikimedia.org/show_bug.cgi?id=45868
class beta::natfix {
    include beta::config

    # List out the instance public IP and private IP as described in OpenStack
    # manager interface
    #
    # FIXME ideally that should be fetched directly from OpenStack
    # configuration to make sure the iptables revwrites are always in sync with
    # the web interface :-D
    #
    $nat_mappings = {
        # eqiad
        'deployment-cache-text02'   => {public_ip  => '208.80.155.135',
                                        private_ip => '10.68.16.16' },
        'deployment-cache-upload02' => {public_ip  => '208.80.155.136',
                                        private_ip => '10.68.17.51' },
        'deployment-cache-bits01'   => {public_ip  => '208.80.155.137',
                                        private_ip => '10.68.16.12' },
        'deployment-eventlogging02' => {public_ip  => '208.80.155.138',
                                        private_ip => '10.68.16.52' },
        'deployment-cache-mobile03' => {public_ip  => '208.80.155.139',
                                        private_ip => '10.68.16.13' },

        # A wide variety of hosts are reachable via a public web proxy.
        'labs_shared_proxy' => {public_ip  => '208.80.155.156',
                                private_ip => '10.68.16.65'},

    }
    create_resources( 'beta::natdestrewrite', $nat_mappings )

    # Allow ssh inbound from deployment-bastion.eqiad.wmflabs for scap
    ferm::rule { 'deployment-bastion-scap-ssh':
        ensure  => present,
        rule    => "proto tcp dport ssh saddr ${::beta::config::bastion_ip} ACCEPT;",
        require => Ferm::Rule['bastion-ssh'],
    }
}
