class role::labs::bastion {
    system_role { "role::labs::bastion":
        description => "Labs bastion host (with mosh enabled)"
    }

    package { 'mosh':
        ensure => present
    }
}
