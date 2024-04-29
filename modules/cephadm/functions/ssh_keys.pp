# SPDX-License-Identifier: Apache-2.0
function cephadm::ssh_keys (
    Stdlib::Host $cephadm_controller,
) >> String[1] {
    $pql = @("PQL")
        inventory[facts.cephadm.ssh.key] {
		    certname = "${cephadm_controller}"
        }
        | PQL
    wmflib::puppetdb_query($pql).reduce('') |$memo, $res| {
        "${memo}${res['facts.cephadm.ssh.key']}\n"
    }
}
