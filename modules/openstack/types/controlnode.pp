# SPDX-License-Identifier: Apache-2.0
# @summary type to represent an openstack control plane node
type OpenStack::ControlNode = Struct[{
  host_fqdn          => Stdlib::Fqdn,
  cloud_private_fqdn => Stdlib::Fqdn,
}]
