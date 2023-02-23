# SPDX-License-Identifier: Apache-2.0
# Restart opensearch-dashboards periodically to mitigate slow memory leak
# See: https://phabricator.wikimedia.org/T327161

class toil::opensearch_dashboards_restart (
  $ensure = present,
) {

  systemd::timer::job { 'opensearch-dashboards-periodic-restart':
    ensure          => $ensure,
    logging_enabled => false,
    user            => 'root',
    description     => 'Restart opensearch-dashboards periodically for slow memory leak T327161',
    command         => '/usr/bin/systemctl try-restart opensearch-dashboards.service',
    splay           => 3600, # seconds
    interval        => {
      'start'    => 'OnCalendar',
      'interval' => 'Wednesday 16:00 UTC',
    },
  }

}
