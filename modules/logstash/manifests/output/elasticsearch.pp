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
    $ensure          = present,
    $host            = '127.0.0.1',
    $index           = "${title}-%{+YYYY.MM.dd}",
    $prefix          = "${title}-",
    $port            = 9200,
    $guard_condition = undef,
    $manage_indices  = false,
    $priority        = 10,
    $template        = undef,
    $template_name   = $title,
    $plugin_id       = "output/elasticsearch/${title}",
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
            content => template('logstash/curator/cleanup.yaml.erb')
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
