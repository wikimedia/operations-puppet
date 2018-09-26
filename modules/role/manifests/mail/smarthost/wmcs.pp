class role::mail::smarthost::wmcs(
    $prometheus_nodes = hiera('prometheus_nodes', []), # lint:ignore:wmf_styleguide
) {

    include ::profile::base::firewall

    system::role { 'mail::smarthost::wmcs':
        description => 'WMCS Outbound Mail Smarthost',
    }

    class { '::profile::mail::smarthost':
        prometheus_nodes       => $prometheus_nodes,
        relay_from_hosts       => $network::constants::labs_networks,
        root_alias_rcpt        => 'root@wmflabs.org',
        envelope_rewrite_rules => [ '*@*.eqiad.wmflabs  root@wmflabs.org  F' ],
    }
}
