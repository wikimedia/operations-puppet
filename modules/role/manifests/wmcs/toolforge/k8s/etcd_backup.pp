# SPDX-License-Identifier: Apache-2.0
class role::wmcs::toolforge::k8s::etcd_backup () {
    include profile::labs::cindermount::srv
    include profile::toolforge::base
    include profile::toolforge::infrastructure
    include profile::toolforge::k8s::etcd_backup
}
