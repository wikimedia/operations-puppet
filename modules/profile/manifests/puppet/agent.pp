# SPDX-License-Identifier: Apache-2.0
# @summary install and configure puppet agent
# @param puppetmaster the puppet server
# @param ca_server the ca server
# @param ca_source to source of the CA file
# @param manage_ca_file if true manage the puppet ca file
# @param interval the, in minutes, interval to perform puppet runs
# @param environment the agent environment
# @param serialization_format the serilasation format of catalogs
# @param dns_alt_names a list of dns alt names
# @param certificate_revocation The level of certificate revocation to perform
class profile::puppet::agent(
  String                          $puppetmaster           = lookup('puppetmaster'),
  Optional[String[1]]             $ca_server              = lookup('puppet_ca_server'),
  Stdlib::Filesource              $ca_source              = lookup('puppet_ca_source'),
  Boolean                         $manage_ca_file         = lookup('manage_puppet_ca_file'),
  Integer[1,59]                   $interval               = lookup('profile::puppet::agent::interval'),
  Optional[String[1]]             $environment            = lookup('profile::puppet::agent::environment'),
  Enum['pson', 'json', 'msgpack'] $serialization_format   = lookup('profile::puppet::agent::serialization_format'),
  Array[Stdlib::Fqdn]             $dns_alt_names          = lookup('profile::puppet::agent::dns_alt_names'),
  Optional[Enum['chain', 'leaf']] $certificate_revocation = lookup('profile::puppet::agent::certificate_revocation'),
) {

  class { 'puppet::agent':
      ca_source              => $ca_source,
      manage_ca_file         => $manage_ca_file,
      server                 => $puppetmaster,
      ca_server              => $ca_server,
      dns_alt_names          => $dns_alt_names,
      environment            => $environment,
      interval               => $interval,
      certificate_revocation => $certificate_revocation,
  }
  class { 'puppet_statsd':
      statsd_host   => 'statsd.eqiad.wmnet',
      metric_format => 'puppet.<%= metric %>',
  }
  class { 'prometheus::node_puppet_agent': }
  include profile::puppet::client_bucket
}
