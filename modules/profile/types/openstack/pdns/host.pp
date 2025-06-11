# SPDX-License-Identifier: Apache-2.0
# @summary Type definition for configuring different interfaces and hostnames
# a Cloud VPS DNS host has.
type Profile::Openstack::Pdns::Host = Struct[{
  auth_fqdn    => Stdlib::Fqdn,
  private_fqdn => Stdlib::Fqdn,
  host_fqdn    => Stdlib::Fqdn,
}]
