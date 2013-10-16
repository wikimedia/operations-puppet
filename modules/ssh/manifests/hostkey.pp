define ssh::hostkey($ip, $key) {
    $host = regsubst($title, '^([^\.]+)\..*$', '\1')

    sshkey { $title:
        ensure => present,
        type   => ssh-rsa,
        key    => $key,
    }

    sshkey { $host:
        ensure => present,
        type   => ssh-rsa,
        key    => $key,
    }

    sshkey { $ip:
        ensure => present,
        type   => ssh-rsa,
        key    => $key,
    }
}
