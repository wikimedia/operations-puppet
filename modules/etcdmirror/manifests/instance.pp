# == define etcdmirror::instance
#
# Sets up a replication mirroring from a prefix on one etcd server to a prefix
# on another.
#
# === Parameters
#
# [*src*] URI for the etcd server we're replicating from
#
# [*src_path*] Source path to replicate from (relative to /v2/keys)
#
# [*dst*] URI for the etcd server we're replicating todo
#
# [*dst_path*] Destination path to replicate to (relative to /v2/keys)
#
# [*enable*] If service is to be enabled or not
#
# [*strip*] strip away the origin key from the resulting key
#
define etcdmirror::instance($src, $src_path, $dst, $dst_path, $enable, $strip) {
    require_package('etcd-mirror')

    # safe version of the title
    $prefix = regsubst("etcdmirror${title}", '\W', '-', 'G')

    $service_status = $enable ? {
        true    => 'running',
        default => 'stopped',
    }

    $service_params = { ensure => $service_status, }
    base::service_unit { $prefix:
        ensure          => present,
        systemd         => true,
        declare_service => true,
        refresh         => false,
        service_params  => $service_params,
        template_name   => 'etcd-mirror',
    }

    systemd::syslog { $prefix:
        owner        => 'root',
        group        => 'root',
        log_filename => 'syslog.log',
    }

    if ($enable) {
        nrpe::monitor_systemd_unit_state{ $prefix: }
    }
}
