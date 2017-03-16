# vim:sw=4 ts=4 sts=4 et:

# = Define: logstash::conf
#
# This resource type represents a collection of Logstash configuration
# directives.
#
# == Parameters:
#
# - $content: String containing Logstash configuration directives. Either this
#       or $source must be specified. Undefined by default.
# - $source: Path to file containing Logstash configuration directives. Either
#       this or $content must be specified. Undefined by default.
# - $priority: Configuration loading priority. Default 10.
# - $ensure: Whether the config should exist.
#
# == Sample usage:
#
#   logstash::conf { 'debug':
#     content => 'output { stdout { codec => rubydebug } }'
#   }
#
define logstash::conf(
    $content  = undef,
    $source   = undef,
    $priority = 10,
    $ensure   = present,
) {
    include ::logstash

    $config_name = inline_template('<%= @title.gsub(/\W/, "-") %>')

    file { "/etc/logstash/conf.d/${priority}-${config_name}.conf":
        ensure  => $ensure,
        content => $content,
        source  => $source,
        owner   => 'logstash',
        group   => 'logstash',
        mode    => '0444',
        notify  => Service['logstash'],
    }
}
