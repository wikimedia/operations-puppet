class profile::openstack::base::networktests (
    String[1]           $region                = lookup('porfile::openstack::base::region'),
    Stdlib::Fqdn        $sshbastion            = lookup('profile::openstack::base::networktests::sshbastion'),
    Hash                $envvars               = lookup('profile::openstack::base::networktests::envvars'),
    Array[Stdlib::Fqdn] $openstack_controllers = lookup('profile::openstack::base::openstack_controllers'),
) {
    class { 'cmd_checklist_runner': }

    class { 'openstack::monitor::networktests':
        timer_active => false, # not providing a lot of value today
        #timer_active => ($::facts['networking']['hostname'] == $openstack_controllers[1].split("\.")[1]), # not [0] because decoupling
        region       => $region,
        sshbastion   => $sshbastion,
        envvars      => $envvars,
    }
}
