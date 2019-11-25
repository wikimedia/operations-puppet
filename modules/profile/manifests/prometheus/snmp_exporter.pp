class profile::prometheus::snmp_exporter (
    # Allow Prometheus (ops instance) hosts to talk to netmon's snmp_exporter in
    # eqiad and codfw.
    $prometheus_nodes = hiera('prometheus_all_nodes'),
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

    prometheus::snmp_exporter::module { 'pdu_sentry4_codfw':
        template  => 'servertech_sentry4',
        community => $passwords::network::snmp_ro_community_pdus_codfw,
    }

    prometheus::snmp_exporter::module { 'pdu_sentry4_eqiad':
        template  => 'servertech_sentry4',
        community => $passwords::network::snmp_ro_community,
    }

    prometheus::snmp_exporter::module { 'pdu_sentry4_ulsfo':
        template  => 'servertech_sentry4',
        community => $passwords::network::snmp_ro_community,
    }

    prometheus::snmp_exporter::module { 'pdu_sentry4_esams':
        template  => 'servertech_sentry4',
        community => $passwords::network::snmp_ro_community,
    }

    prometheus::snmp_exporter::module { 'pdu_sentry4_eqsin':
        template  => 'servertech_sentry4',
        community => $passwords::network::snmp_ro_community,
    }

    if $::realm == 'labs' {
        $ferm_srange = '$LABS_NETWORKS'
    } else {
        $prometheus_ferm_nodes = join($prometheus_nodes, ' ')
        $ferm_srange = "(@resolve((${prometheus_ferm_nodes})) @resolve((${prometheus_ferm_nodes}), AAAA))"
    }

    ferm::service { 'prometheus-snmp-exporter':
        proto  => 'tcp',
        port   => '9116',
        srange => $ferm_srange,
    }
}
