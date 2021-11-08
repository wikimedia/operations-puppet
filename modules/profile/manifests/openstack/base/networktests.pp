class profile::openstack::base::networktests (
    String[1]    $region     = lookup('porfile::openstack::base::region'),
    Stdlib::Fqdn $sshbastion = lookup('profile::openstack::base::networktests::sshbastion'),
    Hash         $envvars    = lookup('profile::openstack::base::networktests::envvars'),
) {

    class { 'openstack::monitor::networktests':
        region     => $region,
        sshbastion => $sshbastion,
        envvars    => $envvars,
    }
}
