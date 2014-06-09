class role::labs::bastion {
    system::role { 'role::labs::bastion':
        description => 'Labs bastion host (with mosh enabled)',
    }

    if ! $::labs_bastion_banner_skip {
        file { '/etc/ssh/sshd_banner':
            owner   => 'root',
            group   => 'root',
            mode    => '0444',
            content => "\nIf you are having access problems, please see: https://wikitech.wikimedia.org/wiki/Access#Accessing_public_and_private_instances\n",
        }
    }

    if versioncmp($::lsbdistrelease, '12.04') >= 0 {
        package { 'mosh':
            ensure => present,
        }
    }
}
