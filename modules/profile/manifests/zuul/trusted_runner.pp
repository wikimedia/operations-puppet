# SPDX-License-Identifier: Apache-2.0
# new zuul (T393873) - trusted runners
class profile::zuul::trusted_runner {

    ensure_packages(['docker.io'])

    service { 'docker':
        ensure => running,
        enable => true,
    }
}
