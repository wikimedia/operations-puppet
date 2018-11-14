define fifo_log_demux::instance(
    String $user = 'root',
    Stdlib::Absolutepath $fifo = '/var/run/fifo.pipe',
    Stdlib::Absolutepath $socket = '/var/run/log.socket',
    Boolean $socket_activation = false,
    String $wanted_by = undef,
) {
    include fifo_log_demux

    systemd::service { "fifo-log-demux@${title}":
        ensure  => present,
        restart => true,
        content => systemd_template('fifo-log-demux@'),
    }

    if $socket_activation {
        systemd::unit { "fifo-log-demux@${title}.socket":
            ensure  => present,
            content => systemd_template('fifo-log-demux@.socket'),
        }
    }
}
