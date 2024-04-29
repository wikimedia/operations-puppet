# SPDX-License-Identifier: Apache-2.0
# == Class: cephadm::target
#
# @summary Installs the requirements for a node to be a cephadm target
# i.e. a node that will be part of a cephadm-managed Ceph cluster.
#
# @param [Stdlib::Fqdn] cephadm_controller
#     cephadm controller node (which will be allowed access to the ssh port)
class cephadm::target(
    Optional[Stdlib::Fqdn] $cephadm_controller = undef,
) {
    # podman, and necessary packages for running Ceph containers.
    ensure_packages([
        'catatonit',
        'fuse-overlayfs',
        'thin-provisioning-tools',
        'podman',
    ])

    if $cephadm_controller {
        firewall::service { 'cephadm-ssh':
            proto  => 'tcp',
            port   => '22',
            srange => [ $cephadm_controller ],
        }

        file { '/etc/ssh/userkeys/root.d/cephadm':
            mode    => '0444',
            content => cephadm::ssh_keys($cephadm_controller),
        }
    } else {
        file { '/etc/ssh/userkeys/root.d/cephadm':
            ensure => absent,
        }
    }
}
