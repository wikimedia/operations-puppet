# == Define: prometheus::blackbox_check_endpoint
#
# Registers a blackbox exporter-compatible job
#
# = Parameters
#
# [*targets*]
#   An Array of target URLs.  Becomes an entry in `static_configs`.
#   https://prometheus.io/docs/prometheus/latest/configuration/configuration/#static_config
#
# [*site*]
#   The Prometheus datacenter instance this job will be enabled on.
#
# [*job_name*]
#   The job name assigned to scraped metrics by default.  Defaults to $title.
#
# [*params*]
#   Optional HTTP URL parameters.
#
# [*metrics_path*]
#   The blackbox exporter endpoint to scrape.
#
# [*timeout*]
#   The scrape request timeout.
#
# [*relabel_configs*]
#   Prometheus relabeling configuration.
#   https://prometheus.io/docs/prometheus/latest/configuration/configuration/#relabel_config

define prometheus::blackbox_check_endpoint (
    Array[String] $targets,
    String $site = $::site,
    String $job_name = $title,
    Hash $params = {},
    String $metrics_path = '/probe',
    String $timeout = '10s',
    String $exporter_address = '127.0.0.1:9115',
    Array[Hash] $relabel_configs = [
        {
            'source_labels' => ['__address__'],
            'target_label'  => '__param_target',
        },
        {
            'source_labels' => ['__param_target'],
            'target_label'  => 'instance',
        },
        {
            'target_label' => '__address__',
            'replacement'  => $exporter_address,
        },
    ]
) {
    # Placeholder define will record options into PuppetDB to be reconstituted by a query
}
