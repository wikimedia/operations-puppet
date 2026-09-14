# SPDX-License-Identifier: Apache-2.0

# Run the Arelion exporter on the active Netmon server
class profile::netmon::arelion_exporter(
    Stdlib::Fqdn $active_server = lookup('netmon_server'),
    String       $username      = lookup('profile::netmon::arelion_exporter::username'),
    String       $password      = lookup('profile::netmon::arelion_exporter::password'),
    String       $client_id     = lookup('profile::netmon::arelion_exporter::client_id'),
    String       $client_secret = lookup('profile::netmon::arelion_exporter::client_secret'),
) {
    class { '::prometheus::node_arelion':
        active_server => $active_server,
        username      => $username,
        password      => $password,
        client_id     => $client_id,
        client_secret => $client_secret,
    }
}
