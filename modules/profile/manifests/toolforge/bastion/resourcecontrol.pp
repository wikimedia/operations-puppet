#
# [*nproc]
#  limits.conf nproc
#
class profile::toolforge::bastion::resourcecontrol(
    $nproc = hiera('profile::toolforge::bastion::nproc',30),
){
    class { 'systemd::slice::all_users':
        all_users_slice_config  => file('profile/toolforge/bastion-user-resource-control.conf'),
    }

    file {'/etc/security/limits.conf':
        ensure  => file,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('profile/toolforge/limits.conf.erb'),
    }
}
