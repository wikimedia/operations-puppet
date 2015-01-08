define ssh::hostkey($ip, $key, $type) {
    $host = regsubst($title, '^([^\.]+)\..*$', '\1')

    sshkey { $title:
        ensure => present,
        type   => $type,
        key    => $key,
    }

    sshkey { $host:
        ensure => present,
        type   => $type,
        key    => $key,
    }

    sshkey { $ip:
        ensure => present,
        type   => $type,
        key    => $key,
    }
}
