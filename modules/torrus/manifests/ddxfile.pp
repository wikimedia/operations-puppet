# Definition: misc::torrus::discovery
#
# This definition generates a torrus discovery DDX file, which Torrus
# will use to compile its XML config files from SNMP
#
# Parameters:
#   - $subtree: the Torrus subtree path used in the XML config file
#   - $domain: The domain name to use for SNMP host names
#   - $snmp_community: The SNMP community needed to query
#   - $hosts: A list of hosts
define torrus::ddxfile(
    $subtree,
    $domain = '',
    $snmp_community = 'public',
    $hosts = []
) {

    file { "/etc/torrus/discovery/${title}.ddx":
        require => File['/etc/torrus/discovery'],
        content => template('torrus/generic.ddx.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        before  => Exec['torrus-discovery'],
        notify  => Exec['torrus-discovery'],
    }
}
