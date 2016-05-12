# vim: set tabstop=4 shiftwidth=4 softtabstop=4 expandtab textwidth=80 smarttab

class role::labs::puppetmaster {

    include network::constants
    include ldap::role::config::labs

    $labs_metal = hiera('labs_baremetal_servers', [])
    $ldapconfig = $ldap::role::config::labs::ldapconfig
    $basedn = $ldapconfig['basedn']
    $novaconfig = hiera_hash('novaconfig', {})
    $labs_instance_range = $novaconfig['fixed_range']


    # Only allow puppet access from the instances
    $allow_from = flatten([$labs_instance_range, '208.80.154.14', $labs_metal])

    class { '::puppetmaster':
        server_name    => hiera('labs_puppet_master'),
        allow_from     => $allow_from,
        is_labs_master => true,
        config         => {
            'thin_storeconfigs' => false,
            'node_terminus'     => 'ldap',
            'ldapserver'        => $ldapconfig['servernames'][0],
            'ldapbase'          => "ou=hosts,${basedn}",
            'ldapstring'        => '(&(objectclass=puppetClient)(associatedDomain=%s))',
            'ldapuser'          => $ldapconfig['proxyagent'],
            'ldappassword'      => $ldapconfig['proxypass'],
            'ldaptls'           => true,
            'autosign'          => true,
        };
    }

    if ! defined(Class['puppetmaster::certmanager']) {
        class { 'puppetmaster::certmanager':
            remote_cert_cleaner => hiera('labs_certmanager_hostname'),
        }
    }
}
