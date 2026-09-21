# SPDX-License-Identifier: Apache-2.0
class profile::toolforge::k8s::etcd_backup () {
    class { 'profile::wmcs::etcd::backup':
        etcd_hosts => wmflib::role::hosts('wmcs::toolforge::k8s::etcd'),
    }
    contain 'profile::wmcs::etcd::backup'
}
