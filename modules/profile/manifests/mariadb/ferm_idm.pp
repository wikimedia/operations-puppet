# SPDX-License-Identifier: Apache-2.0
# Firewall rules for the misc db host used by idm.wikimedia.org
class profile::mariadb::ferm_idm {
    firewall::service { 'idm':
        proto   => 'tcp',
        port    => 3306,
        notrack => true,
        srange  => ['idm1001.wikimedia.org', 'idm2001.wikimedia.org'],
    }
    firewall::service { 'idm-test':
        proto   => 'tcp',
        port    => 3306,
        notrack => true,
        srange  => ['idm-test1001.wikimedia.org'],
    }
}
