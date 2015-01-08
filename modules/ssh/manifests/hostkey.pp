define ssh::hostkey($ip, $key, $type) {
    $host = regsubst($title, '^([^\.]+)\..*$', '\1')

    sshkey { $title:
        ensure       => present,
        type         => $type,
        key          => $key,
        host_aliases => [ $host, $ip ],
    }
}
