# == Define: logstash::output::statsd
#
# Configure logstash to output to statsd
#
# Metric names are formed as "${namespace}.${sender}.${metric}" following the
# Etsy naming style. $namespace will be omitted if set to an empty string and
# can be formed using Logstash "%{foo}" style printf substution based on the
# contents of the Logstash event being processed. $sender will have dots
# replaced with underscores. These conventions are enforced by the Logstash
# output plugin, so figure out how deal with them for your use case.
#
# == Parameters:
# - $ensure: Whether the config should exist. Default present.
# - $host: statsd server. Default '127.0.0.1'.
# - $port: statsd server port. Default 8125.
# - $guard_condition: Logstash condition to require to pass events to output.
#     Default undef.
# - $namespace: The statsd namespace to use for this metric.
#     Default 'logstash'.
# - $sender: Name of the sender. Dots will be replaced with underscores.
#     Default $host.
# - $count: Hash of metric_name => count values. Default undef.
# - $decrement: Array of metric names to decrement. Default undef.
# - $gauge: Hash of metric_name => gauge values. Default undef.
# - $increment: Array of metric names to increment. Default undef.
# - $set: Hash of metric_name => set values. Default undef.
# - $timing: Hash of metric_name => timing values. Default undef.
# - $sample_rate: The sample rate for the metric. Default 1.
# - $plugin_id: Name associated with Logstash metrics
#
# == Sample usage:
#
#   logstash::output::statsd { 'MW_channel_rate':
#       guard_condition => '[type] == "mediawiki" and "es" in [tags]',
#       namespace       => 'logstash.rate',
#       sender          => 'mediawiki',
#       increment       => [ "%{channel}.%{level}" ],
#   }
#
define logstash::output::statsd(
    $ensure          = present,
    $host            = '127.0.0.1',
    $port            = 8125,
    $guard_condition = undef,
    $namespace       = 'logstash',
    $sender          = $host,
    $count           = undef,
    $decrement       = undef,
    $gauge           = undef,
    $increment       = undef,
    $set             = undef,
    $timing          = undef,
    $sample_rate     = 1,
    $plugin_id       = "output/statsd/${title}",
) {
    logstash::conf { "output-statsd-${title}":
        ensure   => $ensure,
        content  => template('logstash/output/statsd.erb'),
        # FIXME - top-scope var without namespace, will break in puppet 2.8
        # lint:ignore:variable_scope
        priority => $priority,
        # lint:endignore
    }
}
# vim:sw=4 ts=4 sts=4 et:
