# == Class: profile::webperf::coal_web
#
# Provision the coal_web service on a webperf node.
# Consumes from Kafka EventLogging, and produces to Graphite.
#
# Contact: performance-team@wikimedia.org
# See also: <https://wikitech.wikimedia.org/wiki/Webperf>
#
class profile::webperf::coal_web {
    class { '::coal::web': }
}
