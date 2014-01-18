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

    # List out the instance public IP and private IP as described in OpenStack
    # manager interface
    #
    # FIXME ideally that should be fetched directly from OpenStack
    # configuration to make sure the iptables revwrites are always in sync with
    # the web interface :-D
    #
    $nat_mappings = {
        'deployment-cache-text1'    => {public_ip  => '208.80.153.219',
                                        private_ip => '10.4.1.133' },
        'deployment-cache-upload04' => {public_ip  => '208.80.153.242',
                                        private_ip => '10.4.0.211' },
        'deployment-cache-bits03'   => {public_ip  => '208.80.153.243',
                                        private_ip => '10.4.0.51' },
        'deployment-eventlogging'   => {public_ip  => '208.80.153.244',
                                        private_ip => '10.4.0.48' },
        'deployment-cache-mobile01' => {public_ip  => '208.80.153.143',
                                        private_ip => '10.4.1.82' },
    }
    create_resources( 'beta::natdestrewrite', $nat_mappings )
}
