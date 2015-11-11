# == Class: elasticsearch::log::hot_threads
#
# Install a cron job to log the hot threads.
#
class elasticsearch::log::hot_threads {
    $script_name = 'elasticsearch_hot_threads_logger.py'
    $script = "/usr/local/bin/${script_name}"
    $log = '/var/log/elasticsearch/elasticsearch_hot_threads.log'
    file { $script:
        source => "puppet:///modules/elasticsearch/${script_name}",
        mode   => '0555',
    }

    cron { 'elasticsearch-hot-threads-log':
        command => "python ${script} >> ${log} 2>&1",
        #So the destination directory exists
        require => Package['elasticsearch'],
        user    => 'elasticsearch',
        minute  => '*/5',
    }

    # The logrotate configuration for Elasticsearch will roll these logs just
    # fine.
}
