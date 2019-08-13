# == Class profile::samplicator
# Sets up Samplicator: UDP datagrams duplicator
# Actions:
#     * Calls the samplicator module
#     * Open ACL
# === Parameters
#  [*port*]
#   Port to listen for datagrams on
#  [*targets*]
#   List of "hostname(or IP)/port" to duplicate datagrams to
# === Example
#       include profile::samplicator
class profile::samplicator (
  Stdlib::Port $port = lookup('profile::samplicator::port'),
  Array[String] $targets = lookup('profile::samplicator::targets'),
  ) {

    class { '::samplicator':
        port    => $port,
        targets => $targets,
    }

    ferm::service { 'samplicator':
        proto => 'udp',
        port  => $port,
        desc  => 'samplicator',
      srange  => '($NETWORK_INFRA $MGMT_NETWORKS)',
    }
}
