# = Define: prometheus::es_exporter_config
#
# This resource type represents a prometheus-es-exporter configuration file.
#
# == Parameters:
#
# - $source: Path to file containing prometheus-es-exporter configuration.
# - $priority: Configuration loading priority. Default 10.
# - $ensure: Whether the config should exist.
#
# == Sample usage:
#
#   prometheus::es_exporter_config { 'mediawiki-errors:
#       source => 'puppet:///modules/profile/prometheus/es_exporter/mediawiki-errors.cfg'
#   }
#
define prometheus::es_exporter_config(
    $source   = undef,
    $priority = 10,
    $ensure   = present,
) {
    include prometheus::es_exporter

    $config_name = inline_template('<%= @title.gsub(/\W/, "-") %>')

    file { "/etc/prometheus-es-exporter/${priority}-${config_name}.cfg":
        ensure => $ensure,
        source => $source,
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        notify => Service['prometheus-es-exporter'],
        # TODO: add validate_cmd
    }
}
