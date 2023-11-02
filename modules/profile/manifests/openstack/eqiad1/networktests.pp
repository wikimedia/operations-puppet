class profile::openstack::eqiad1::networktests (
    Stdlib::Fqdn                  $sshbastion              = lookup('profile::openstack::eqiad1::networktests::sshbastion'),
    Hash                          $envvars                 = lookup('profile::openstack::eqiad1::networktests::envvars'),
    Array[OpenStack::ControlNode] $openstack_control_nodes = lookup('profile::openstack::eqiad1::openstack_control_nodes'),
) {
    class { 'profile::openstack::base::networktests':
        region                  => 'eqiad1',
        sshbastion              => $sshbastion,
        envvars                 => $envvars,
        openstack_control_nodes => $openstack_control_nodes,
    }
}
