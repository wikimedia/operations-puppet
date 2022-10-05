# SPDX-License-Identifier: Apache-2.0
# = Class: prometheus::node_local_crontabs
#
# Periodically export local crontab information via node-exporter
# textfile collector.
# This is exclusively tailored for toolforge grid nodes.
class profile::prometheus::node_local_crontabs {
    class { 'prometheus::node_local_crontabs': }

    sudo::user { 'prometheus_sudo_for_local_crontab':
        ensure     => 'present',
        user       => 'prometheus',
        privileges => [
            'ALL=(root) NOPASSWD: /bin/ls -1 /var/spool/cron/crontabs/',
        ],
    }

    systemd::timer::job { 'prometheus-local-crontabs':
        ensure      => present,
        description => 'Regular job to collect number of crontabs installed on this host',
        user        => 'prometheus',
        command     => '/usr/local/bin/prometheus-local-crontabs',
        # Run every 5 minutes
        interval    => {'start' => 'OnCalendar', 'interval' => '*-*-* *:00/5:00'},
    }
}
