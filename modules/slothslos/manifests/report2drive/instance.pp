# SPDX-License-Identifier: Apache-2.0
##
# == Define: slothslos::report2drive::instance
#
# @summary
# Manage a single `report2drive` instance configuration, drive key file,
# and scheduled systemd timer.
#
# @description
# This defined type creates the per-instance drive key file and INI file
# required by `report2drive`, then schedules a systemd timer job to invoke the
# helper script periodically. It separates instance-specific drive and Grafana
# settings so multiple report2drive jobs can be configured independently.
#
# @param dashboardreporter_app_settings_dashuid [String] Grafana dashboard UID
#   used by the reporter application.
# @param drive_upload_folder_id [String] Google Drive folder ID where report
#   exports are uploaded.
# @param drive_key [String] JSON content of the service account key used for
#   Drive uploads. This content is written to a per-instance file under
#   `/etc/report2drive`.
# @param prometheus_slos_query [String] Prometheus query string used to
#   collect SLO data for reporting.
# @param user [String] System user that owns the generated files and runs the
#   report2drive timer job.
# @param ensure [Wmflib::Ensure, Optional] Desired resource state for the
#   generated files and timer. Defaults to `present`.
# @param grafana_hostname [Stdlib::HTTPUrl, Optional] Grafana API host URL.
# @param grafana_api [String, Optional] Optional Grafana API path to use in
#   the generated configuration.
# @param grafana_bearer_token [String, Optional] Grafana bearer token used
#   to authenticate with the Grafana API.
# @param dashboardreporter_app_settings_additional_configs [Hash[String, String], Optional]
#   Additional key/value settings to pass into the dashboard reporter app.
# @param report_var_defaults [Hash[String, String], Optional] Optional default
#   report variables for the generated instance configuration.
# @param prometheus_hostname [Stdlib::HTTPUrl, Optional] Prometheus host URL.
# @param http_retries [Integer, Optional] Number of HTTP retry attempts for
#   remote requests.
# @param http_sslverify [Boolean, Optional] Whether HTTP SSL verification is
#   enabled for remote requests.
define slothslos::report2drive::instance (
    String                         $dashboardreporter_app_settings_dashuid,
    String                         $drive_upload_folder_id,
    String                         $drive_key,
    String                         $prometheus_slos_query,
    String                         $user,
    Optional[Wmflib::Ensure]       $ensure                                            = present,
    Optional[Stdlib::HTTPUrl]      $grafana_hostname                                  = undef,
    Optional[String]               $grafana_api                                       = undef,
    Optional[String]               $grafana_bearer_token                              = undef,
    Optional[Hash[String, String]] $dashboardreporter_app_settings_additional_configs = {},
    Optional[Hash[String, String]] $report_var_defaults                               = {},
    Optional[Stdlib::HTTPUrl]      $prometheus_hostname                               = undef,
    Optional[Integer]              $http_retries                                      = undef,
    Optional[Boolean]              $http_sslverify                                    = undef,
) {
    $drive_key_file = "/etc/report2drive/${title}_drive_key.json"
    file { $drive_key_file:
        ensure  => stdlib::ensure($ensure, 'file'),
        mode    => '0550',
        owner   => $user,
        content => $drive_key,
    }

    $ini_file = "/etc/report2drive/${title}.ini"
    file { $ini_file:
        ensure  => stdlib::ensure($ensure, 'file'),
        mode    => '0550',
        owner   => $user,
        content => epp('slothslos/report2drive.ini.epp', {
            grafana_hostname                                  => $grafana_hostname,
            grafana_api                                       => $grafana_api,
            grafana_bearer_token                              => $grafana_bearer_token,
            dashboardreporter_app_settings_dashuid            => $dashboardreporter_app_settings_dashuid,
            dashboardreporter_app_settings_additional_configs => $dashboardreporter_app_settings_additional_configs,
            report_var_defaults                               => $report_var_defaults,
            drive_upload_folder_id                            => $drive_upload_folder_id,
            drive_key_file                                    => $drive_key_file,
            prometheus_hostname                               => $prometheus_hostname,
            prometheus_slos_query                             => $prometheus_slos_query,
            http_retries                                      => $http_retries,
            http_sslverify                                    => $http_sslverify,
        }),
    }

    systemd::timer::job { "report2drive-${title}":
        ensure             => $ensure,
        description        => "Report generation (Instance: ${title}).",
        user               => $user,
        group              => $user,
        ignore_errors      => false,
        environment        => {
            'http_proxy'  => 'http://webproxy:8080',
            'https_proxy' => 'http://webproxy:8080',
            'HTTP_PROXY'  => 'http://webproxy:8080',
            'HTTPS_PROXY' => 'http://webproxy:8080',
            'no_proxy'    => '127.0.0.1,::1,localhost,.wmnet,.wikimedia.org,.wikipedia.org,.wikibooks.org,.wikiquote.org,.wiktionary.org,.wikisource.org,.wikispecies.org,.wikiversity.org,.wikidata.org,.mediawiki.org,.wikinews.org,.wikivoyage.org',
            'NO_PROXY'    => '127.0.0.1,::1,localhost,.wmnet,.wikimedia.org,.wikipedia.org,.wikibooks.org,.wikiquote.org,.wiktionary.org,.wikisource.org,.wikispecies.org,.wikiversity.org,.wikidata.org,.mediawiki.org,.wikinews.org,.wikivoyage.org',
        },
        command            => "/usr/local/bin/report2drive --offset 1 --config-file ${ini_file}",
        interval           => [{ 'start' => 'OnCalendar', 'interval' => '*-01,04,07,10-02 04:00:00' },],
        splay              => 3600,
        fixed_random_delay => true,
        logging_enabled    => true,
        syslog_identifier  => "report2drive-${title}",
    }
}
