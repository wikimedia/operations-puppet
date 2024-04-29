# SPDX-License-Identifier: Apache-2.0
# Class: profile::cephadm::controller
#
# This profile is for the node on which cephadm is installed (and thus
# is used to setup and manage the rest of the Ceph cluster).
class profile::cephadm::controller(
    Optional[String] $ceph_repository_component =
    lookup('profile::cephadm::cephadm_component', { default_value => undef }),
) {
    require profile::cephadm::target

    # cephadm::cephadm has a sensible default, only override it
    # if hiera specifies something else
    if $ceph_repository_component {
        class { 'cephadm::cephadm':
            ceph_repository_component => $ceph_repository_component,
        }
    } else {
        class { 'cephadm::cephadm': }
    }
}
