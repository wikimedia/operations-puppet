class ssh::client {
    package { 'openssh-client':
        ensure => latest,
    }

    file { '/etc/ssh/ssh_known_hosts':
        content => generate('/usr/local/bin/sshknowngen'),
        backup  => false,
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
    }

}
