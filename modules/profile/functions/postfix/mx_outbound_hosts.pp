# SPDX-License-Identifier: Apache-2.0
#
# Returns an array of hosts which are tagged with mx_out, which indicates
# they send outbound mail
function profile::postfix::mx_outbound_hosts() >> Array[Stdlib::Fqdn] {
    $pql =
        @(PQL)
        nodes[certname] {
            resources {
                type = 'Class' and
                tag = 'mx_out'
            }
        }
        | PQL
    wmflib::puppetdb_query($pql).map |$node| {
        $node['certname']
    }.sort
}
