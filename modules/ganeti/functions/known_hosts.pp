# SPDX-License-Identifier: Apache-2.0
#
# Queries for the SSH public host keys of all the members of a given ganeti
# cluster
function ganeti::known_hosts (
    Stdlib::Host $ganeti_cluster,

) >> String[1] {
    $pql = @("PQL")
        inventory[certname, facts.ssh.rsa.key] {
            facts.ganeti_cluster = "${ganeti_cluster}"
        }
        | PQL
    wmflib::puppetdb_query($pql).reduce('') |$memo, $host| {
        "${memo}${host['certname']} ssh-rsa ${host['facts.ssh.rsa.key']}\n"
    }
}
