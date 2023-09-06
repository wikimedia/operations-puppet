# SPDX-License-Identifier: Apache-2.0
class profile::parsoid::testreduce(
    Boolean $install_node = lookup('profile::parsoid::testreduce::install_node'),
){
    class { 'testreduce':
        install_node => $install_node,
    }

    rsync::quickdatacopy { 'testreduce-update':
        source_host         => 'testreduce1001.eqiad.wmnet',
        dest_host           => 'testreduce1001.eqiad.wmnet',
        auto_sync           => false,
        module_path         => '/srv/data',
        server_uses_stunnel => true,
    }

    ensure_packages(['make', 'g++'])
}
