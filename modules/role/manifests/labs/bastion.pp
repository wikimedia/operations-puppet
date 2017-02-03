# filtertags: labs-project-bastion labs-project-mwoffliner
class role::labs::bastion {
    system::role { 'role::labs::bastion':
        description => 'Labs bastion host (with mosh enabled)',
    }

    file { '/etc/ssh/sshd_banner':
        ensure  => absent
    }

    package { 'mosh':
        ensure => present,
    }
}
