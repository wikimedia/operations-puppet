# SPDX-License-Identifier: Apache-2.0
# Class: profile::ceph::admin
#
# This profile installs the tools that an SRE uses on a Ceph administration
# host. profile::ceph::client supplies the cluster configuration and the
# administrative keyring.
#
# Later work adds the desired state file, the apply tooling and the gateway
# credentials to this profile.
#
# See #T435608
#
# @param packages The administration tools to install.
class profile::ceph::admin (
    Array[String[1]] $packages = lookup('profile::ceph::admin::packages'),
) {
    ensure_packages($packages)
}
