# SPDX-License-Identifier: Apache-2.0
class k8s::base_dirs {
    # TODO: create this directory in the deb package,
    # drop this class completely afterwards.
    file { '/etc/kubernetes':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }
}
