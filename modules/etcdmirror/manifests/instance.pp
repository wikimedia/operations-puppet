define etcdmirror::instance($sources, $dst) {
    require_package('etcd-mirror')

    # Source host
    $src = $sources[$title]

    $data = split($title, '@')
    $src_path = $data[0]
    $dst_prefix = $data[1]
    $dst_path = "/${dst_prefix}${src_path}"
    # safe version of the title
    $prefix = regsubst("etcdmirror${title}", '\W', '-', 'G')

    base::service_unit { $prefix:
        ensure          => present,
        systemd         => true,
        declare_service => false,
        template_name   => 'etcd-mirror',
    }

    systemd::syslog { $prefix:
        owner        => 'root',
        group        => 'root',
        log_filename => 'syslog.log',
    }
}
