# == Define: logstash::output::elasticsearch
#
# Configure logstash to output to elasticsearch
#
# == Parameters:
# - $ensure: Whether the config should exist. Default present.
# - $host: Elasticsearch server. Default '127.0.0.1'.
# - $index: Index to write events to. Default '${title}-%{+YYYY.MM.dd}'.
# - $prefix: indices with this prefix will be cleaned up. Used by the
#       `cleanup.yaml.erb` template.
# - $port: Elasticsearch server port. Default 9200.
# - $guard_condition: Logstash condition to require to pass events to output.
#       Default undef.
# - $manage_indices: Whether cron jobs should be installed to manage
#       elasticsearch indices. Default false.
# - $priority: Configuration loading priority. Default 10.
# - $template: Path to Elasticsearch mapping template. Default undef.
# - $template_name: Name of Elasticsearch mapping template.
#       Default $title.
# - $plugin_id: Name associated with Logstash metrics
# - $cleanup_template: curator actions template file
# - $timestring: curator age filter `timestring`
# - $unit: curator age filter `unit`
# - $unit_count: curator age filter `unit_count`
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
    String                                     $prefix           = "${title}-",
    Integer                                    $port             = 9200,
    Optional[String]                           $guard_condition  = undef,
    Boolean                                    $manage_indices   = false,
    Integer                                    $priority         = 10,
    Optional[String]                           $template         = undef,
    String                                     $template_name    = $title,
    String                                     $plugin_id        = "output/elasticsearch/${title}",
    String                                     $cleanup_template = 'logstash/curator/cleanup.yaml.erb',
    String                                     $timestring       = '%Y.%m.%d',
    Integer                                    $unit_count       = 91,
    Enum['seconds', 'minutes', 'hours', 'days', 'weeks', 'months', 'years'] $unit = 'days',
) {
    require ::logstash::output::elasticsearch::scripts

    logstash::conf{ "output-elasticsearch-${title}":
        ensure   => $ensure,
        content  => template('logstash/output/elasticsearch.erb'),
        priority => $priority,
    }

    $ensure_cron = $manage_indices ? {
        true    => 'present',
        default => 'absent'
    }

    # curator cluster config template require a list of hosts
    $http_port = $port
    $cluster_name = $title
    $curator_hosts = [ $host ]

    elasticsearch::curator::config {
        "config-${title}":
            content => template('elasticsearch/curator_cluster.yaml.erb');
        "cleanup_${title}":
            content => template($cleanup_template)
    }

    cron { "logstash_cleanup_indices_${title}":
        ensure  => $ensure_cron,
        command => "/usr/bin/curator --config /etc/curator/config-${title}.yaml /etc/curator/cleanup_${title}.yaml > /dev/null",
        user    => 'root',
        hour    => 0,
        minute  => 42,
        require => Elasticsearch::Curator::Config["cleanup_${title}"],
    }
}
# vim:sw=4 ts=4 sts=4 et:
