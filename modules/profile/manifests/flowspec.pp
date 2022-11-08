# SPDX-License-Identifier: Apache-2.0
# == Class profile::flowspec
#
# Install and manage a Flowspec controller and its requirements
#
# === Parameters
#
#  [*asns*]
#    site to AS# mapping
#
class profile::flowspec (
  Hash[String, Integer] $asns = lookup('asns'),
  ) {

    # Get the list of infrastructure prefixes per sites
    include network::constants
    $network_infra = $::network::constants::network_infra

    class { 'gobgpd':
        config_content => template('profile/flowspec/gobgpd.conf.erb'),
    }

    ferm::service { 'bgp':
        proto  => 'tcp',
        port   => '179',
        desc   => 'BGP',
        srange => '($NETWORK_INFRA)',
    }
    profile::contact { $title:
        contacts => ['ayounsi']
    }
}
