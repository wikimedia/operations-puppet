class prometheus::node_exim_queue (
    Wmflib::Ensure $ensure  = 'present',
) {
    $script = '/usr/local/bin/prometheus-node-exim-queue'
    file { $script:
        ensure => $ensure,
        mode   => '0555',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/prometheus/usr/local/bin/prometheus-node-exim-queue.sh',
    }

    systemd::timer::job { 'prometheus-node-exim-queue':
        ensure      => $ensure,
        user        => 'root',
        description => 'Generate exim queue stats for the prometheus node exporter',
        command     => $script,
        interval    => {
            'start'    => 'OnCalendar',
            'interval' => 'minutely',
        },
        require     => [File[$script], Class['prometheus::node_exporter'],]
    }
}
