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
# === Examples
#       include profile::rpkivalidator
#
class profile::rpkivalidator(
  Optional[String] $http_proxy = lookup('http_proxy', {'default_value' => undef}),
  Stdlib::Port $rtr_port = lookup('rtr_port', {'default_value' => 3323}),
){

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
    profile::contact { $title:
        contacts => ['ayounsi']
    }
}
