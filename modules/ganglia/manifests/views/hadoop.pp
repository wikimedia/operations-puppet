class ganglia::views::hadoop(
    $master,
    $worker_regex,
    $ensure = 'present') {

    ganglia::web::view { 'hadoop':
        ensure => $ensure,
        graphs => [
            # ResourceManager active applications
            {
                'host_regex'   => $master,
                'metric_regex' => 'Hadoop.ResourceManager.QueueMetrics.*ActiveApplications',
                'type'         => 'stack',
            },
            # ResourceManager failed applications
            {
                'host_regex'   => $master,
                'metric_regex' => 'Hadoop.ResourceManager.QueueMetrics.*AppsFailed',
                'type'         => 'stack',
            },
            # NodeManager containers running
            {
                'host_regex'   => $worker_regex,
                'metric_regex' => 'Hadoop.NodeManager.NodeManagerMetrics.ContainersRunning',
                'type'         => 'stack',
            },
            # NodeManager Allocated Memeory GB
            {
                'host_regex'   => $worker_regex,
                'metric_regex' => 'Hadoop.NodeManager.NodeManagerMetrics.AllocatedGB',
                'type'         => 'stack',
            },
            # Worker Node bytes_in
            {
                'host_regex'   => $worker_regex,
                'metric_regex' => 'bytes_in',
                'type'         => 'stack',
            },
            # Worker Node bytes_out
            {
                'host_regex'   => $worker_regex,
                'metric_regex' => 'bytes_out',
                'type'         => 'stack',
            },
            # Primary NameNode File activity
            {
                'host_regex'   => $master,
                'metric_regex' => 'Hadoop.NameNode.NameNodeActivity.Files(Created|Deleted|Renamed|Appended)',
                'type'         => 'line',
            },
            # Worker Node /proc/diskstat bytes written per second
            {
            # FIXME - top-scope var without namespace ($worker_regex), will break in puppet 2.8
            # lint:ignore:variable_scope
                'host_regex'   => $worker_regex,
                'metric_regex' => "diskstat_(${kafka_log_disks_regex})_write_bytes_per_sec",
                'type'         => 'stack',
            },
            # /proc/diskstat bytes read per second
            {
                'host_regex'   => $worker_regex,
                'metric_regex' => "diskstat_(${kafka_log_disks_regex})_read_bytes_per_sec",
                'type'         => 'stack',
            },
            # Worker Node /proc/diskstat disk utilization %
            {
                'host_regex'   => $worker_regex,
                'metric_regex' => "diskstat_(${kafka_log_disks_regex})_percent_io_time",
                'type'         => 'line',
            },
            # Worker Node /proc/diskstat IO time
            {
                'host_regex'   => $worker_regex,
                'metric_regex' => "diskstat_(${kafka_log_disks_regex})_io_time",
                'type'         => 'line',
            },
            # lint:endignore
            # Worker Node 15 minute load average
            {
                'host_regex'   => $worker_regex,
                'metric_regex' => 'load_fifteen',
                'type'         => 'line',
            },
            # Worker Node IO wait
            {
                'host_regex'   => $worker_regex,
                'metric_regex' => 'cpu_wio',
                'type'         => 'line',
            },
        ],
    }
}

