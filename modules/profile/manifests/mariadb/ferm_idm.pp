# SPDX-License-Identifier: Apache-2.0
# Firewall rules for the misc db host used by idm.wikimedia.org
class profile::mariadb::ferm_idm {
    ferm::service { 'idm':
        proto   => 'tcp',
        port    => '3306',
        notrack => true,
        srange  => '@resolve((idm1001.wikimedia.org idm2001.wikimedia.org))',
    }

    ferm::service { 'idm-test':
        proto   => 'tcp',
        port    => '3306',
        notrack => true,
        srange  => '@resolve((idm-test1001.wikimedia.org idm-test2001.wikimedia.org))',
    }
}
