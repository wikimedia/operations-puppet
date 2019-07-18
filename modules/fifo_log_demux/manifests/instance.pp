define fifo_log_demux::instance(
    String $user = 'root',
    Stdlib::Absolutepath $fifo = '/var/run/fifo.pipe',
    Stdlib::Absolutepath $socket = '/var/run/log.socket',
    Boolean $socket_activation = false,
    String $wanted_by = undef,
    Boolean $create_fifo = false,
    Optional[String] $fifo_owner = undef,
    Optional[String] $fifo_group = undef,
    Optional[Stdlib::Filemode] $fifo_mode = undef,
) {
    include fifo_log_demux

    if $create_fifo {
        exec { "create_fifo@${title}":
            command => "/usr/bin/mkfifo ${fifo}",
            creates => $fifo,
        }

        file { $fifo:
            ensure  => present,
            owner   => $fifo_owner,
            group   => $fifo_group,
            mode    => $fifo_mode,
            require => Exec["create_fifo@${title}"],
        }
    }

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
