# SPDX-License-Identifier: Apache-2.0
# new zuul (T393873) - executors
class profile::zuul::executor {

    ensure_packages(['docker.io'])

    service { 'docker':
        ensure => running,
        enable => true,
    }
}
