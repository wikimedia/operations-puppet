# == Class: profile::rpkivalidator
#
# This profile installs and configure a RPKI validator - T220669
#
# Actions:
#     * Calls the routinator module
#     * Open ACL for the RTR protocol
#     * Add Icinga monitoring for the RTR port
#
# === Parameters
#  [*proxy*]
#   "hostname:port" of proxy for rsync (optional)
#
#  [*rtr_port*]
#   Port on which the RPKI-to-router daemon listens
#
# [*prometheus_nodes*]
#   Prometheus nodes that should be allowed to query the exporter (optional)
#
# === Examples
#       include profile::rpkivalidator
#
class profile::rpkivalidator(
  Optional[String] $http_proxy = hiera('http_proxy', undef),
  Optional[Stdlib::Port] $rtr_port = hiera('rtr_port', 3323),
  Optional[Array[Stdlib::Fqdn]] $prometheus_nodes = hiera('prometheus_nodes', undef),
  ) {
    # Remove the http:// prefix to only keep webproxy.%{::site}.wmnet:8080
    # As rsync doesn't like it
    if $http_proxy {
        $proxy = regsubst($http_proxy, 'http:\/\/(.*)$', '\1')
    } else {
        $proxy = undef
    }
    class { '::routinator':
        proxy    => $proxy,
        rtr_port => $rtr_port,
    }

    if $prometheus_nodes {
        $prometheus_nodes_ferm = join($prometheus_nodes, ' ')
        ferm::service { 'routinator-prometheus-acl':
            desc   => 'Routinator prometheus port',
            proto  => 'tcp',
            port   => '9556',
            srange => "(@resolve((${prometheus_nodes_ferm})) @resolve((${prometheus_nodes_ferm}), AAAA))",
        }
    }
    # Standard port is 323 but using 3323 to run the daemon as unpriviledge user
    # MGMT_NETWORKS is also included as devices can (should?) querry it over their mgmt port
    ferm::service { 'rpkivalidator-rtr-acl':
        desc   => 'RPKI to router port',
        proto  => 'tcp',
        port   => $rtr_port,
        srange => '($NETWORK_INFRA $MGMT_NETWORKS)',
    }
    monitoring::service { 'rpkivalidator-rtr-mon':
        description   => 'RPKI Validator RTR port',
        check_command => "check_tcp!${rtr_port}",
        notes_url     => 'https://wikitech.wikimedia.org/wiki/RPKI#RPKI_to_router_port',
    }


}
