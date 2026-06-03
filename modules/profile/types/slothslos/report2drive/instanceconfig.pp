# SPDX-License-Identifier: Apache-2.0
type Profile::Slothslos::Report2drive::InstanceConfig = Struct[{
    grafana_bearer_token                              => Optional[String],
    drive_key                                         => Profile::Slothslos::Report2drive::DriveKey,
    enabled                                           => Boolean,
    dashboardreporter_app_settings_dashuid            => String,
    drive_upload_folder_id                            => String,
    prometheus_slos_query                             => String,
    grafana_hostname                                  => Optional[Stdlib::HTTPUrl],
    grafana_api                                       => Optional[String],
    dashboardreporter_app_settings_additional_configs => Optional[Hash[String, String]],
    report_var_defaults                               => Optional[Hash[String, String]],
    prometheus_hostname                               => Optional[Stdlib::HTTPUrl],
    http_retries                                      => Optional[Integer],
    http_sslverify                                    => Optional[Boolean],
}]
