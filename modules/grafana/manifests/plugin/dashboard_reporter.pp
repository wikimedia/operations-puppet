# SPDX-License-Identifier: Apache-2.0
#
# deploy and configure the grafana-dashboard-reporter-app plugin
# https://github.com/mahendrapaipuri/grafana-dashboard-reporter-app

class grafana::plugin::dashboard_reporter(
    String $grafana_token = undef,
    Stdlib::Unixpath $provisioning_plugins_path = '/etc/grafana/provisioning/plugins'
) {

    # https://gitlab.wikimedia.org/repos/sre/grafana-dashboard-reporter-app/-/tree/main/debian
    ensure_packages('grafana-dashboard-reporter-app')

    file { "${provisioning_plugins_path}/mahendrapaipuri-dashboardreporter-app.yaml":
        ensure  => present,
        group   => 'grafana',
        content => template('grafana/plugin/grafana-dashboard-reporter-app/app.yaml.erb'),
    }

}
