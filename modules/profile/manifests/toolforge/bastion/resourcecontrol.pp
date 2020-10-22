#
# [*nproc]
#  limits.conf nproc
#
class profile::toolforge::bastion::resourcecontrol(
    Integer $nproc = lookup('profile::toolforge::bastion::nproc', {default_value => 250}),
){
    class { 'systemd::slice::all_users':
        all_users_slice_config => file('profile/toolforge/bastion-user-resource-control.conf'),
        pkg_ensure             => 'latest',
    }

    class { 'toolforge::bastion_proc_management':
        project => $::labsproject,
    }

    file {'/etc/security/limits.conf':
        ensure  => file,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('profile/toolforge/limits.conf.erb'),
    }
}
