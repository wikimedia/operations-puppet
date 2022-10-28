# SPDX-License-Identifier: Apache-2.0
class k8s::base_dirs {
    # TODO: This directory is created by kubernetes debian packages >= 1.23, drop after all clusters have been upgraded
    file { '/etc/kubernetes':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }
}
