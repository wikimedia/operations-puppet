class profile::openstack::codfw1dev::networktests (
    Stdlib::Fqdn        $sshbastion            = lookup('profile::openstack::codfw1dev::networktests::sshbastion'),
    Hash                $envvars               = lookup('profile::openstack::codfw1dev::networktests::envvars'),
    Array[Stdlib::Fqdn] $openstack_controllers = lookup('profile::openstack::codfw1dev::openstack_controllers'),
) {
    class { 'profile::openstack::base::networktests':
        region                => 'codfw1dev',
        sshbastion            => $sshbastion,
        envvars               => $envvars,
        openstack_controllers => $openstack_controllers,
    }
}
