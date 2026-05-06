# SPDX-License-Identifier: Apache-2.0
# new zuul (T393873) - trusted build nodes
class profile::zuul::trusted_build_node {

    ensure_packages(['docker.io'])

    service { 'docker':
        ensure => running,
        enable => true,
    }
}
