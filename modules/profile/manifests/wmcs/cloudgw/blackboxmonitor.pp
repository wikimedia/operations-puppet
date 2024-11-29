#SPDX-License-Identifier: Apache-2.0
class profile::wmcs::cloudgw::blackboxmonitor (
    Array[String[1]] $datacenters = lookup('datacenters'),
    String[1]        $wan_fqdn    = lookup('profile::wmcs::cloudgw::blackboxmonitor::wan_fqdn'),
    String[1]        $virt_fqdn   = lookup('profile::wmcs::cloudgw::blackboxmonitor::virt_fqdn'),
    Boolean          $do_ipv6     = lookup('profile::wmcs::cloudgw::blackboxmonitor::do_ipv6'),
) {

    $dc_list = ['eqiad', 'codfw']
    if $do_ipv6 {
        $inet_fams = ['ip4', 'ip6']
    } else {
        $inet_fams = ['ip4']
    }

    $datacenters.each |$dc| {
        if $dc in $dc_list {
            prometheus::blackbox::check::icmp { "${wan_fqdn}-from-${dc}":
                site           => $dc,
                instance_label => $wan_fqdn,
                team           => 'wmcs',
                ip4            => dnsquery::a($wan_fqdn)[0],
                # prometheus::check::icmp will ignore the IPv6 address if ip_families does not contain ip6
                ip6            => ($do_ipv6).bool2str(dnsquery::aaaa($wan_fqdn).then |$x| { $x[0] }, '::1'),
                ip_families    => $inet_fams,
            }

            prometheus::blackbox::check::icmp { "${virt_fqdn}-from-${dc}":
                site           => $dc,
                instance_label => $virt_fqdn,
                team           => 'wmcs',
                ip4            => dnsquery::a($virt_fqdn)[0],
                # prometheus::check::icmp will ignore the IPv6 address if ip_families does not contain ip6
                ip6            => ($do_ipv6).bool2str(dnsquery::aaaa($wan_fqdn).then |$x| { $x[0] }, '::1'),
                ip_families    => $inet_fams,
            }
        }
    }
}
