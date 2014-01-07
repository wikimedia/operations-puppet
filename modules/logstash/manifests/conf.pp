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
    include logstash

    $config_file = inline_template('<%= @title.gsub(/\W/, "-") %>')

    file { "${logstash::config_dir}/${priority}-${config_file}.conf":
        ensure  => $ensure,
        content => $content,
        source  => $source,
        require => Package['logstash'],
        notify  => Service['logstash'],
    }
}
