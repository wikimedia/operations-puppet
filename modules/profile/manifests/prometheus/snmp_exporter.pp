# SPDX-License-Identifier: Apache-2.0
class profile::prometheus::snmp_exporter (
  # As of Jan 2022 all SNMP polling happens from codfw/eqiad netmon
  # hosts, therefore allow all Prometheus hosts to talk to snmp_exporter
    Array[Stdlib::Host] $prometheus_all_nodes = lookup('prometheus_all_nodes'),
) {
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
        $ferm_srange = '$LABS_NETWORKS'
    } else {
        $prometheus_ferm_nodes = join($prometheus_all_nodes, ' ')
        $ferm_srange = "@resolve((${prometheus_ferm_nodes}))"
    }

    ferm::service { 'prometheus-snmp-exporter':
        proto  => 'tcp',
        port   => '9116',
        srange => $ferm_srange,
    }
}
