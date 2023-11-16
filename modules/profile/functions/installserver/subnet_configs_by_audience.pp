# SPDX-License-Identifier: Apache-2.0
function profile::installserver::subnet_configs_by_audience(Hash[String[1], Hash] $datacenter_config, Enum['public', 'private'] $audience) {
  Hash(
    $datacenter_config[$audience].filter |$subnet_name, $_| { $subnet_name !~ /(lvs|kube)/ }.map |$subnet_name, $subnet_config| {
      [
        $subnet_name, {
          'network_mask' => wmflib::cidr2mask($subnet_config['ipv4']),
          'broadcast_address' => wmflib::cidr_last_address($subnet_config['ipv4']),
          'gateway_ip' => wmflib::cidr_first_address($subnet_config['ipv4']),
          'ip' => Stdlib::IP::Address.new(split($subnet_config['ipv4'], '/')[0])
        }
      ]
    }
  )
}
