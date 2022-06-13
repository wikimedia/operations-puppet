# SPDX-License-Identifier: Apache-2.0
# == Class: coal::common
#
# Coal 
#   1) processes and stores NavTiming metrics (coal::processor)
#   2) Delivers metrics to performance.wikimedia.org (coal::web)
#
# This file contains directives that are common to both parts
#
class coal::common {
    # Clean up some things that used to make sense but don't any more
    user { 'coal':
        ensure => absent,
    }

    group { 'coal':
        ensure => absent,
    }

    file { '/usr/local/bin/coal':
        ensure => absent,
    }

    file { '/usr/local/bin/coal-web':
        ensure => absent,
    }

    # Make sure that scap target is there for all types.
    scap::target { 'performance/coal':
        service_name => 'coal',
        deploy_user  => 'deploy-service',
        sudo_rules   => [
            'ALL=(root) NOPASSWD: /usr/sbin/service uwsgi-coal start',
            'ALL=(root) NOPASSWD: /usr/sbin/service uwsgi-coal stop',
            'ALL=(root) NOPASSWD: /usr/sbin/service uwsgi-coal restart',
            'ALL=(root) NOPASSWD: /usr/sbin/service uwsgi-coal reload',
            'ALL=(root) NOPASSWD: /usr/sbin/service uwsgi-coal status'
        ]
    }
}
