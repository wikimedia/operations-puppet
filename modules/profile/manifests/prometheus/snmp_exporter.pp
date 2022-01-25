class profile::prometheus::snmp_exporter {
    include passwords::network

    class { '::prometheus::snmp_exporter': }

    prometheus::snmp_exporter::module { 'pdu_codfw':
        template  => 'servertech_sentry3',
        community => $passwords::network::snmp_ro_community,
    }

    prometheus::snmp_exporter::module { 'pdu_eqiad':
        template  => 'servertech_sentry3',
        community => $passwords::network::snmp_ro_community,
    }

    prometheus::snmp_exporter::module { 'pdu_sentry4_codfw':
        template  => 'servertech_sentry4',
        community => $passwords::network::snmp_ro_community,
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

    prometheus::snmp_exporter::module { 'pdu_sentry4_drmrs':
        template  => 'servertech_sentry4',
        community => $passwords::network::snmp_ro_community,
    }

    if $::realm == 'labs' {
        ferm::service { 'prometheus-snmp-exporter':
            proto  => 'tcp',
            port   => '9116',
            srange => '$LABS_NETWORKS'
        }
    }
}
