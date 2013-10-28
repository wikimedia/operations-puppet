class role::labs::bastion {
    system::role { "role::labs::bastion":
        description => "Labs bastion host (with mosh enabled)"
    }

    file { '/etc/ssh/sshd_banner':
        owner   => root,
        group   => root,
        mode    => '0444',
        content => "\nIf you are having access problems, please see:https://labsconsole.wikimedia.org/wiki/Access#Accessing_public_and_private_instances\n",
    }

    package { 'mosh':
        ensure => present
    }
}
