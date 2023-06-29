# SPDX-License-Identifier: Apache-2.0
# @summary take general squid::acl and converts the src role and dst hosts to ip addresses
# @example
#   $acl = {
#     'task' => 'T1234',
#     'port' => 9876,
#     'src'  => ['sretest']
#     'dst'  => ['bastion.example.org']
#   }
#   squid::acl::normalise($acl) >> {
#     'task' => 'T1234',
#     'port' => 9876,
#     'src'  => ['10.64.48.138', '2620:0:861:107:10:64:48:138', '10.64.48.139', '2620:0:861:107:10:64:48:139'],
#     'dst'  => ['192.0.2.1', '2001:db8::1'],
#   }
# @param acl the acl to normalise
function squid::acl::normalise (
    Hash[String[1], Squid::Acl] $acl,
) >> Hash[String[1], Squid::Acl] {
    Hash($acl.map |$name, $acl| {
        $src = $acl['src'].map |$role| { wmflib::role::ips($role) }.flatten.sort.unique
        $dst = $acl['dst_type'] ? {
            'host'  => $acl['dst'].map |$host| { dnsquery::lookup($host) }.flatten.sort.unique,
            default => $acl['dst'],
        }
        [$name, $acl + {'src' => $src, 'dst' => $dst}]
    })
}
