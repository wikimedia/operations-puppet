# SPDX-License-Identifier: Apache-2.0
# @summary etcd cluster for Cloud VPS infrastructure services (e.g. requestctl)
class role::wmcs::cloudinfra_etcd () {
    include profile::firewall
    include profile::wmcs::etcd
}
