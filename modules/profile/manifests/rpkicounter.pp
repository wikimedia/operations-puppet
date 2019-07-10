# == Class: profile::rpkicounter
#
# This profile installs and configure rpkicounter
#
# Actions:
#     * Calls the rpkicounter module
#     * Configure Kafkatee to pipe to rpkicounter
#     * Open ACLs for Prometheus
#
# === Parameters
#
# [*prometheus_nodes*]
#   Prometheus nodes that should be allowed to query rpkicounter
#
#  [*proxy*]
#   "hostname:port" of proxy for https (optional)
#
# === Examples
#       include ::profile::kafkatee::webrequest::base (requirement)
#       include profile::rpkicounter
#
class profile::rpkicounter(
  Array[Stdlib::Fqdn] $prometheus_nodes = hiera('prometheus_nodes'),
  Optional[String] $https_proxy = hiera('http_proxy', undef),
  ) {

  class { '::rpkicounter': }

  if $https_proxy {
      $proxy = "https_proxy=${https_proxy} "
  } else {
      $proxy = ''
  }

  include ::profile::kafkatee::webrequest::base

  kafkatee::output { 'rpkicounter':
      instance_name => 'webrequest',
      destination   => "${proxy}/usr/bin/python3 /usr/local/bin/rpkicounter.py",
      type          => 'pipe',
      sample        => 100,
  }


  $prometheus_nodes_ferm = join($prometheus_nodes, ' ')
  ferm::service { 'rpkicounter-prometheus-acl':
      desc   => 'rpkicounter prometheus port',
      proto  => 'tcp',
      port   => '9200',
      srange => "(@resolve((${prometheus_nodes_ferm})) @resolve((${prometheus_nodes_ferm}), AAAA))",
  }

}
