class role::labs::bastion {
    system::role { 'labs::bastion':
        description => 'Cloud VPS bastion host (with mosh enabled)',
    }

    file { '/etc/ssh/sshd_banner':
        ensure  => absent
    }

    package { 'mosh':
        ensure => present,
    }
}
