class profile::openstack::eqiad1::networktests (
    Stdlib::Fqdn        $sshbastion            = lookup('profile::openstack::eqiad1::networktests::sshbastion'),
    Hash                $envvars               = lookup('profile::openstack::eqiad1::networktests::envvars'),
    Array[Stdlib::Fqdn] $openstack_controllers = lookup('profile::openstack::eqiad1::openstack_controllers'),
) {
    class { 'profile::openstack::base::networktests':
        region                => 'eqiad1',
        sshbastion            => $sshbastion,
        envvars               => $envvars,
        openstack_controllers => $openstack_controllers,
    }
}
