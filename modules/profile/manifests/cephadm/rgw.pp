# SPDX-License-Identifier: Apache-2.0
# Class: profile::cephadm::rgw
#
# This profile provides the necessary setup for a cephadm-controlled
# rgw node - the nodes that provide the S3 (and maybe swift) protocol
# frontend to a Ceph cluster.
class profile::cephadm::rgw(
) {
    require profile::cephadm::target

    ferm::service { 'rgw-https':
        proto   => 'tcp',
        notrack => true,
        port    => 443,
        }

    # so we get pool/depool/etc. scripts
    class { 'conftool::scripts': }
}
