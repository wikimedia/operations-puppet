# == Define: logstash::output::elasticsearch
#
# Configure logstash to output to elasticsearch
#
# == Parameters:
# - $ensure: Whether the config should exist. Default present.
# - $host: Elasticsearch server. Default '127.0.0.1'.
# - $flush_size: Maximum number of events to buffer before sending.
#       Default 5000.
# - $idle_flush_time: Maxmimum seconds to wait between sends. Default 1.
# - $index: Index to write events to. Default '${title}-%{+YYYY.MM.dd}'.
# - $port: Elasticsearch server port. Default 9200.
# - $guard_condition: Logstash condition to require to pass events to output.
#       Default undef.
# - $manage_indices: Whether cron jobs should be installed to manage
#       elasticsearch indices. Default false.
# - $priority: Configuration loading priority. Default 10.
# - $template: Path to Elasticsearch mapping template. Default undef.
# - $template_name: Name of Elasticsearch mapping template.
#       Default $title.
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
    $flush_size      = 5000,
    $idle_flush_time = 1,
    $index           = "${title}-%{+YYYY.MM.dd}",
    $port            = 9200,
    $guard_condition = undef,
    $manage_indices  = false,
    $priority        = 10,
    $template        = undef,
    $template_name   = $title,
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

    cron { "logstash_delete_index_${title}":
        ensure  => $ensure_cron,
        command => "/usr/local/bin/logstash_delete_index.sh ${host}:${port} \"${title}-$(date -d '-31days' +\\%Y.\\%m.\\%d)\"",
        user    => 'root',
        hour    => 0,
        minute  => 42,
        require => File['/usr/local/bin/logstash_delete_index.sh'],
    }

    cron { "logstash_clear_cache_${title}":
        ensure  => absent, # T144396 - removing the clear cache mechanism to validate it is not needed anymore
        command => "/usr/local/bin/logstash_clear_cache.sh ${host}:${port} '${title}-*'",
        user    => 'root',
        minute  => 5 * fqdn_rand(12, "logstash_clear_cache_${title}"),
        require => File['/usr/local/bin/logstash_clear_cache.sh'],
    }
}
# vim:sw=4 ts=4 sts=4 et:
