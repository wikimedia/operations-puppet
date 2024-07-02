# SPDX-License-Identifier: Apache-2.0
# sets up preseeding dir and config on an install server
class profile::installserver::preseed (
  Hash $preseed_per_hostname = lookup('profile::installserver::preseed::preseed_per_hostname'),
) {
  include network::constants
  $preseed_subnets = Hash(
    $network::constants::all_network_subnets['production'].map |$datacenter_name, $datacenter_config| {
      $datacenter_config.map |$audience, $audience_config| {
        $audience_config.filter |$subnet_name, $_| {
          $subnet_name !~ /-(lvs|kube)/
        }.map |$subnet_name, $subnet_config| {
          [$subnet_name, {
              'subnet_gateway' => wmflib::cidr_first_address($subnet_config['ipv4']),
              'subnet_mask' => $subnet_name =~ /-virtual-/ ? {
                true => '255.255.255.255',
                default => wmflib::cidr2mask($subnet_config['ipv4']),
              },
              'datacenter_name' => $datacenter_name,
              'public_subnet' => $subnet_name =~ /^public/,
          }]
        }
      }
    }.flatten
  )

  class { 'install_server::preseed_server':
    preseed_subnets      => $preseed_subnets,
    preseed_per_hostname => $preseed_per_hostname,
  }

  # Backup
  $sets = ['srv-autoinstall',
  ]
  backup::set { $sets : }
}
