# SPDX-License-Identifier: Apache-2.0
#
# Returns an array of hosts which are tagged with mx_in, which indicates
# they send inbound mail
function profile::postfix::mx_inbound_hosts() >> Array[Stdlib::Fqdn] {
    $pql =
        @(PQL)
        nodes[certname] {
            resources {
                type = 'Class' and
                tag = 'mx_in'
            }
        }
        | PQL
    wmflib::puppetdb_query($pql).map |$node| {
        $node['certname']
    }.sort
}
