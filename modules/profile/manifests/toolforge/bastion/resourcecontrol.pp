#
# [*nproc]
#  limits.conf nproc
#
class profile::toolforge::bastion::resourcecontrol(
    $nproc = hiera('profile::toolforge::bastion::nproc',30),
){
    # we need systemd >= 239 for resource control using the user-.slice trick
    # this version is provied in stretch-backports
    apt::pin { 'toolforge-bastion-systemd':
        package  => 'systemd',
        pin      => 'version 239*',
        priority => '1001',
    }

    package { 'systemd':
        ensure          => present,
        install_options => ['-t', 'stretch-backports'],
    }

    systemd::unit { 'user-.slice':
        ensure   => present,
        content  => file('profile/toolforge/bastion-user-resource-control.conf'),
        override => true,
    }

    systemd::unit { 'user-0.slice':
        ensure   => present,
        content  => file('profile/toolforge/bastion-root-resource-control.conf'),
        override => true,
    }

    file {'/etc/security/limits.conf':
        ensure  => file,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('profile/toolforge/limits.conf.erb'),
    }
}
