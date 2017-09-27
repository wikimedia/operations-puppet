class profile::prometheus::snmp_exporter (
    $prometheus_nodes = hiera('prometheus_nodes'),
    $prometheus_dns_record_type = hiera('profile::prometheus::dns_record_type', 'AAAA'),
) {
    include passwords::network

    class { '::prometheus::snmp_exporter': }

    prometheus::snmp_exporter::module { 'pdu_codfw':
        template  => 'servertech_sentry3',
        community => $passwords::network::snmp_ro_community_pdus_codfw,
    }

    prometheus::snmp_exporter::module { 'pdu_eqiad':
        template  => 'servertech_sentry3',
        community => $passwords::network::snmp_ro_community,
    }

    if $::realm == 'labs' {
        $ferm_srange = '$LABS_NETWORKS'
    } else {
        $prometheus_ferm_nodes = join($prometheus_nodes, ' ')
        $ferm_srange = "(@resolve((${prometheus_ferm_nodes})) @resolve((${prometheus_ferm_nodes}), ${prometheus_dns_record_type}))"
    }

    ferm::service { 'prometheus-snmp-exporter':
        proto  => 'tcp',
        port   => '9116',
        srange => $ferm_srange,
    }
}
