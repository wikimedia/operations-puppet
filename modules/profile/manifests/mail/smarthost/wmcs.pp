# sets up a mail smarthost for Wikimedia cloud environment
class profile::mail::smarthost::wmcs(
    Array[Stdlib::Host] $prometheus_nodes = lookup('prometheus_nodes', {'default_value' => []}),
){

    include network::constants

    class { '::profile::mail::smarthost':
        prometheus_nodes       => $prometheus_nodes,
        relay_from_hosts       => $network::constants::labs_networks,
        root_alias_rcpt        => 'root@wmflabs.org',
        envelope_rewrite_rules => [ '*@*.eqiad.wmflabs  root@wmflabs.org  F' ],
    }
}
