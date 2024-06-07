class role::labs::bastion {
    file { '/etc/ssh/sshd_banner':
        ensure  => absent
    }

    package { 'mosh':
        ensure => present,
    }
}
