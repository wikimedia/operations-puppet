# SPDX-License-Identifier: Apache-2.0
# @summary profile to add prometheus reports to puppetserver
# @param textfile_directory Location of the node_exporter collector.textfile.directory
# @param report_filename If specified, saves all reports to a single file (must end with .prom)
# @param environments If specified, only creates metrics on reports from these environments
# @param reports If specified, only creates metrics from reports of this type (changes, events, resources, time)
# @param stale_time If specified, delete metric files for nodes that haven't sent reports in X days
class profile::puppetserver::prometheus (
    Stdlib::Unixpath  $textfile_directory = lookup('profile::puppetserver::prometheus::textfile_directory'),
    String[1]         $report_filename    = lookup('profile::puppetserver::prometheus::report_filename'),
    Array[String[1]]  $environments       = lookup('profile::puppetserver::prometheus::environments'),
    Array[String[1]]  $reports            = lookup('profile::puppetserver::prometheus::reports'),
    Optional[Integer] $stale_time         = lookup('profile::puppetserver::prometheus::stale_time'),
) {
    include profile::puppetserver
    $config = wmflib::resource::dump_params().filter |$x| { !$x[1].empty and $x[1] =~ NotUndef }
    file { "${profile::puppetserver::puppet_conf_dir}/prometheus.yaml":
        ensure  => file,
        content => $config.to_yaml,
    }
}
