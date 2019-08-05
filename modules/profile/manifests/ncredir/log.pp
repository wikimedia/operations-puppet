define profile::ncredir::log(
    Wmflib::UserIpPort $ncredirmtail_port,
    Stdlib::Absolutepath $fifo = "/var/log/nginx/ncredir.${title}.pipe",
    Stdlib::Absolutepath $socket = "/var/log/nginx/ncredir.${title}.socket",
    String $fifo_owner = 'www-data',
    String $fifo_group = 'adm',
    Stdlib::Filemode $fifo_mode = '0640',
) {
    fifo_log_demux::instance { "ncredir_${title}":
        user        => 'root',
        fifo        => $fifo,
        socket      => $socket,
        required_by => 'nginx.service',
        create_fifo => true,
        fifo_owner  => $fifo_owner,
        fifo_group  => $fifo_group,
        fifo_mode   => $fifo_mode,
        before      => Service['nginx'],
    }

    file { "/usr/local/bin/ncredirlog-${title}":
        ensure  => present,
        content => template('profile/ncredir/ncredirlog.sh.erb'),
        mode    => '0555',
        owner   => 'root',
        group   => 'root',
    }

    systemd::service { "ncredirmtail@${title}":
        ensure  => present,
        restart => true,
        content => systemd_template('ncredirmtail@'),
    }

    exec { 'mask_default_mtail':
        command => '/bin/systemctl mask mtail.service',
        creates => '/etc/systemd/system/mtail.service',
    }
}
