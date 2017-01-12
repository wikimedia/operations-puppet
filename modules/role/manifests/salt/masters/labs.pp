# A salt master that manages all labs minions
class role::salt::masters::labs {

    $puppet_master = hiera('labs_puppet_master')

    $salt_state_roots    = { 'base' => ['/srv/salt'] }
    $salt_file_roots     = { 'base' => ['/srv/salt'] }
    $salt_pillar_roots   = { 'base' => ['/srv/pillars'] }
    $salt_module_roots   = { 'base' => ['/srv/salt/_modules'] }
    $salt_returner_roots = { 'base' => ['/srv/salt/_returners'] }

    class { 'salt::master':
        salt_runner_dirs    => ['/srv/runners'],
        salt_file_roots     => $salt_file_roots,
        salt_pillar_roots   => $salt_pillar_roots,
        salt_worker_threads => '50',
        salt_state_roots    => $salt_state_roots,
        salt_module_roots   => $salt_module_roots,
        salt_returner_roots => $salt_returner_roots,
        salt_auto_accept    => true,
    }

    if ! defined(Class['puppetmaster::certmanager']) {
        include role::labs::openstack::nova::common
        $novaconfig = $role::labs::openstack::nova::common::novaconfig

        class { 'puppetmaster::certmanager':
            remote_cert_cleaner => hiera('labs_certmanager_hostname'),
        }
    }

    class { 'salt::master::key':
        salt_master_pubkey_type => 'labs',
        salt_master_privkey     => secret('salt/labsmaster.pem'),
    }

}
