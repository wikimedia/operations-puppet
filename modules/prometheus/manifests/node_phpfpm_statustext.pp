# = Class: prometheus::node_phpfpm_statustext
#
# Periodically parse the PHP-FPM status text and export e.g. the number of idle vs busy workers
# via a node_exporter textfile collector.  Needed for tracking metrics when appservers are under
# excessive load and all workers are busy, causing the exporter that scrapes status from the
# HTTP endpoint to fail. https://phabricator.wikimedia.org/T252605
#
# = Parameters
#
# [*outfile*]
#   Path to write the finished textfile-exporter-format file.
#
# [*service*]
#   The name of the systemd service with the php-fpm pool you want to monitor.

class prometheus::node_phpfpm_statustext (
    Wmflib::Ensure $ensure = 'present',
    Pattern[/\.prom$/] $outfile = '/var/lib/prometheus/node.d/phpfpm-statustext.prom',
    Systemd::Servicename $service = 'php7.2-fpm.service',
) {
    $exec = '/usr/local/bin/prometheus-phpfpm-statustext'
    file { $exec:
        ensure => file,
        mode   => '0555',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/prometheus/usr/local/bin/prometheus-phpfpm-statustext.sh',
    }

    # Collect every minute
    systemd::timer::job { 'prometheus-phpfpm-statustext-textfile':
        ensure          => $ensure,
        description     => 'Update PHP-FPM worker count stats exported by node_exporter',
        command         => "${exec} ${service} ${outfile}",
        user            => 'root',
        logging_enabled => false,
        require         => [File[$exec]],
        interval        => {
            'start'    => 'OnUnitInactiveSec',
            'interval' => '60s',
        },
    }
}

