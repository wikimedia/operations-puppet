# mariadb heartbeat capability
class mariadb::heartbeat (
    $enabled    = false,
    $interval   = 1,
    $shard      = 'unknown',
    $datacenter = 'none',
    $socket     = '/run/mysqld/mysqld.sock',
) {


    # custom modified version of pt-heartbeat that includes an
    # extra column "shard"
    file { '/usr/local/bin/pt-heartbeat-wikimedia':
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/mariadb/pt-heartbeat-wikimedia',
    }

    # TODO: This should be moved to systemd::service
    if $enabled {
        exec { 'pt-heartbeat':
            command => "/usr/bin/perl \
            /usr/local/bin/pt-heartbeat-wikimedia \
            --defaults-file=/dev/null \
            --user=root --host=localhost -D heartbeat \
            --shard=${shard} --datacenter=${datacenter} \
            --update --replace --interval=${interval} \
            --set-vars=\"binlog_format=STATEMENT\" \
            -S ${socket} --daemonize \
            --pid /var/run/pt-heartbeat.pid",
            unless  => '/bin/ps --pid $(cat /var/run/pt-heartbeat.pid) \
            > /dev/null 2>&1',
            user    => 'root',
            require => File['/usr/local/bin/pt-heartbeat-wikimedia'],
        }
    } else {
        exec { 'pt-heartbeat-kill':
            command => '/bin/kill -TERM $(cat /var/run/pt-heartbeat.pid)',
            onlyif  => '/bin/ps --pid $(cat /var/run/pt-heartbeat.pid) \
            > /dev/null 2>&1',
            user    => 'root',
        }
    }
}
