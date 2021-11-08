class profile::openstack::codfw1dev::networktests (
    Stdlib::Fqdn $sshbastion = lookup('profile::openstack::codfw1dev::networktests::sshbastion'),
    Hash         $envvars    = lookup('profile::openstack::codfw1dev::networktests::envvars'),
) {
    class { 'profile::openstack::base::networktests':
        region     => 'codfw1dev',
        sshbastion => $sshbastion,
        envvars    => $envvars,
    }
}
