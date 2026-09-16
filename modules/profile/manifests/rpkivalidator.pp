# SPDX-License-Identifier: Apache-2.0
# == Class: profile::rpkivalidator
#
# This profile installs and configure a RPKI validator - T220669
#
# Actions:
#     * Calls the routinator module
#     * Open ACL for the RTR protocol
#     * Add Prometheus monitoring for the RTR
#
# === Parameters
#  [*proxy*]
#   "hostname:port" of proxy for rsync (optional)
#
#  [*rtr_port*]
#   Port on which the RPKI-to-router daemon listens
#
#  [*netmon_server*]
#   Active netmon server, where BGP alerter runs
#
# === Examples
#       include profile::rpkivalidator
#
class profile::rpkivalidator(
  Optional[String] $http_proxy = lookup('http_proxy', {'default_value' => undef}),
  Stdlib::Port $rtr_port = lookup('rtr_port', {'default_value' => 3323}),
  Stdlib::Fqdn $netmon_server = lookup('netmon_server'),
){

    # Remove the http:// prefix to only keep webproxy.%{::site}.wmnet:8080
    # As rsync doesn't like it
    if $http_proxy {
        $proxy = regsubst($http_proxy, 'http:\/\/(.*)$', '\1')
    } else {
        $proxy = undef
    }
    class { 'routinator':
        proxy    => $proxy,
        rtr_port => $rtr_port,
    }

    # Standard port is 323 but using 3323 to run the daemon as unprivilegded user
    # MGMT_NETWORKS is also included as devices can (should?) query it over their mgmt port
    firewall::service { 'rpkivalidator-rtr-acl':
        desc     => 'RPKI to router port',
        proto    => 'tcp',
        port     => $rtr_port,
        src_sets => ['NETWORK_INFRA', 'MGMT_NETWORKS'],
    }

    # Default API port opened for BGPalerter to work
    firewall::service { 'rpkivalidator-api-acl':
        desc   => 'HTTP API',
        proto  => 'tcp',
        port   => 9556,
        srange => [$netmon_server],
    }

    prometheus::blackbox::check::tcp { 'rpkivalidator-rtr':
        port          => $rtr_port,
        team          => 'infrastructure-foundations',
        probe_runbook => 'https://wikitech.wikimedia.org/wiki/RPKI#RPKI_to_router_port',
    }

}
