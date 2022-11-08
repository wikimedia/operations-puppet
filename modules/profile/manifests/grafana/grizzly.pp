# SPDX-License-Identifier: Apache-2.0
# == Class: profile::grafana::grizzly
#
# Grizzly is a tool for managing grafana dashboards, datasources, etc.

class profile::grafana::grizzly (
    String          $grafana_token = lookup('profile::grafana::grizzly::grafana_token'),
    Stdlib::HTTPUrl $grafana_url   = lookup('profile::grafana::grizzly::grafana_url', {'default_value' => 'http://localhost:3000'}),
) {

    class { '::grafana::grizzly':
        grafana_url   => $grafana_url,
        grafana_token => $grafana_token,
    }

}
