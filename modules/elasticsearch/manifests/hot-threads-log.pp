# == Class: elasticsearch::hot-threads-log
#
# Install a cron job to log the hot threads.
#
class elasticsearch::hot-threads-log {
    $script_name = 'elasticsearch_hot_threads_logger.py'
    $script = "/usr/local/bin/$script_name"
    $log = '/var/log/elasticsearch/elasticsearch_hot_threads.log'
    file { $script:
        ensure => file,
        owner  => root,
        group  => root,
        source => "puppet:///modules/elasticsearch/$script_name",
        mode   => '0555',
    }

    cron { 'elasticsearch-hot-threads-log':
        command => "python $script 2>&1 >> $log",
        require => Package[elasticsearch], #So the destination directory exists
        user    => elasticsearch,
        minute  => '*/5',
    }

    # The logrotate configuration for Elasticsearch will roll these logs just
    # fine.
}
