# SPDX-License-Identifier: Apache-2.0
class profile::prometheus::snmp_exporter (
  # As of Jan 2022 all SNMP polling happens from codfw/eqiad netmon
  # hosts, therefore allow all Prometheus hosts to talk to snmp_exporter
    Array[Stdlib::Host] $prometheus_all_nodes = lookup('prometheus_all_nodes'),
    Array[String] $datacenters = lookup('datacenters'),
) {
    include passwords::network

    class { '::prometheus::snmp_exporter': }

    $datacenters.each |$dc| {
        #sentry3 (obsolete?)
        prometheus::snmp_exporter::module { "pdu_${dc}":
            template  => 'servertech_sentry3',
            community => $passwords::network::snmp_ro_community,
        }

        prometheus::snmp_exporter::module { "pdu_pro4x_${dc}":
            template  => 'servertech_pro4x',
            community => $passwords::network::snmp_ro_community,
        }

        prometheus::snmp_exporter::module { "pdu_sentry4_${dc}":
            template  => 'servertech_sentry4',
            community => $passwords::network::snmp_ro_community,
        }
    }

    if $::realm == 'labs' {
        firewall::service { 'prometheus-snmp-exporter':
            proto    => 'tcp',
            port     => 9116,
            src_sets => ['LABS_NETWORKS'],
        }
    } else {
        firewall::service { 'prometheus-snmp-exporter':
            proto  => 'tcp',
            port   => 9116,
            srange => $prometheus_all_nodes,
        }
    }
}
