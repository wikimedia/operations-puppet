# SPDX-License-Identifier: Apache-2.0
# == Class: profile::grafana::plugin::dashboard_reporter
#

class profile::grafana::plugin::dashboard_reporter(
    String $grafana_token = lookup('profile::grafana::plugin::dashboard_reporter::grafana_token'),
) {

    class { '::grafana::plugin::dashboard_reporter':
        grafana_token => $grafana_token,
    }

}
