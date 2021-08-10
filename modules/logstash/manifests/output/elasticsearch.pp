# == Define: logstash::output::elasticsearch
#
# Configure logstash to output to elasticsearch
#
# == Parameters:
# - $ensure: Whether the config should exist. Default present.
# - $host: Elasticsearch server. Default '127.0.0.1'.
# - $index: Index to write events to. Default '${title}-%{+YYYY.MM.dd}'.
# - $port: Elasticsearch server port. Default 9200.
# - $guard_condition: Logstash condition to require to pass events to output.
#       Default undef.
# - $priority: Configuration loading priority. Default 10.
# - $template: Path to Elasticsearch mapping template. Default undef.
# - $template_name: Name of Elasticsearch mapping template.
#       Default $title.
# - $plugin_id: Name associated with Logstash metrics
#
# == Sample usage:
#
#   logstash::output::elasticsearch { 'logstash':
#       host            => '127.0.0.1',
#       guard_condition => '"es" in [tags]',
#       manage_indices  => true,
#   }
#
define logstash::output::elasticsearch(
    Wmflib::Ensure                             $ensure           = present,
    Variant[Stdlib::IP::Address, Stdlib::Fqdn] $host             = '127.0.0.1',
    String                                     $index            = "${title}-%{+YYYY.MM.dd}",
    Integer                                    $port             = 9200,
    Optional[String]                           $guard_condition  = undef,
    Integer                                    $priority         = 10,
    Optional[String]                           $template         = undef,
    String                                     $template_name    = $title,
    String                                     $plugin_id        = "output/elasticsearch/${title}",
) {
    require ::logstash::output::elasticsearch::scripts

    logstash::conf{ "output-elasticsearch-${title}":
        ensure   => $ensure,
        content  => template('logstash/output/elasticsearch.erb'),
        priority => $priority,
    }
}
# vim:sw=4 ts=4 sts=4 et:
