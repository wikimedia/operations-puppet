# SPDX-License-Identifier: Apache-2.0
# == Class: cephadm::cephadm
#
# @summary Prepares a node to be the node from which cephadm is run,
# installing the cephadm package from a suitable component
# (e.g. thirdparty/ceph-reef), creating an ssh keypair for cephadm to
# use & exporting the pubkey, and templating out a suitable config file
# for the cluster.
#
# @param Optional[String] ceph_repository_component
#     Component within our apt repo to install cephadm from
class cephadm::cephadm (
    Optional[String ] $ceph_repository_component = 'thirdparty/ceph-reef',
) {
    apt::package_from_component { 'cephadm':
        component => $ceph_repository_component,
        packages  => ['cephadm'],
        priority  => 1002,
    }
    exec { 'Generate ssh keypair for cephadm use':
        # TODO: You could also use an array here, sometimes that is nice, avoids
        # parsing the command in the shell first
        command => '/usr/bin/ssh-keygen -C "cephadm root ssh key" -f /root/.ssh/id_cephadm -t ed25519 -N ""',
        creates => '/root/.ssh/id_cephadm.pub',
    }
    # TODO will need to template out config for cephadm based on
    # e.g. OSD facts.
}
