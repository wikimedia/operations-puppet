# SPDX-License-Identifier: Apache-2.0
# @summary allows the cloudcontrol hosts to SSH in to clean Puppet
#   certificates for deleted instances
class profile::openstack::base::puppetserver::cert_cleaning (
  Array[OpenStack::ControlNode] $openstack_control_nodes = lookup('profile::openstack::base::openstack_control_nodes'),
) {
  $openstack_control_node_hostnames = $openstack_control_nodes.map |$node| { $node['cloud_private_fqdn'] }

  user { 'certmanager':
    home   => '/nonexistent',
    system => true,
  }

  # Allow remote execution for cert cleanup
  ssh::userkey { 'certmanager.pub':
    content => template('puppetmaster/puppet_cert_manager.pub.erb'),
    user    => 'certmanager',
  }

  sudo::user { 'certmanager':
    privileges => [
      'ALL = (root) NOPASSWD: /usr/bin/puppetserver ca clean --certname *',
      'ALL = (root) NOPASSWD: /usr/bin/puppetserver ca list --all --format json',
    ],
  }

  security::access::config { 'certmanager':
    content  => "+ : certmanager : ${openstack_control_node_hostnames.join(' ')}\n",
    priority => 60,
  }
}
