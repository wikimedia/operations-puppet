# SPDX-License-Identifier: Apache-2.0
# new zuul (T393873) - main server
class profile::zuul::main {

    include ::passwords::mysql::zuul

    ensure_packages(['docker.io'])

    service { 'docker':
        ensure => running,
        enable => true,
    }

    rsyslog::conf { 'zuul':
        content  => file('zuul/rsyslog.conf'),
        priority => 20,
    }
}
