# vim: set tabstop=4 shiftwidth=4 softtabstop=4 expandtab textwidth=80 smarttab

class role::labs::puppetmaster(
    $use_enc = true,
) {

    include network::constants
    include ldap::role::config::labs
    include puppetmaster::labsrootpass

    $labs_metal = hiera('labs_baremetal_servers', [])
    $ldapconfig = $ldap::role::config::labs::ldapconfig
    $basedn = $ldapconfig['basedn']
    $novaconfig = hiera_hash('novaconfig', {})
    $labs_instance_range = $novaconfig['fixed_range']
    $horizon_host = hiera('labs_horizon_host')
    $horizon_host_ip = ipresolve(hiera('labs_horizon_host'), 4)


    # Only allow puppet access from the instances
    $allow_from = flatten([$labs_instance_range, '208.80.154.14', $horizon_host_ip, $labs_metal])

    if $use_enc {
        # Setup ENC
        require_package('python3-yaml', 'python3-ldap3')

        include ldap::yamlcreds

        file { '/usr/local/bin/puppet-enc':
            source => 'puppet:///modules/role/labs/puppet-enc.py',
            mode   => '0555',
            owner  => 'root',
            group  => 'root',
        }

        $encconfig = {
            'node_terminus'  => 'exec',
            'external_nodes' => '/usr/local/bin/puppet-enc',
        }
    } else {
        $encconfig = {
            'ldapserver'    => $ldapconfig['servernames'][0],
            'ldapbase'      => "ou=hosts,${basedn}",
            'ldapstring'    => '(&(objectclass=puppetClient)(associatedDomain=%s))',
            'ldapuser'      => $ldapconfig['proxyagent'],
            'ldappassword'  => $ldapconfig['proxypass'],
            'ldaptls'       => true,
            'node_terminus' => 'ldap'
        }
    }
    class { '::puppetmaster':
        server_name      => hiera('labs_puppet_master'),
        allow_from       => $allow_from,
        secure_private   => false,
        extra_auth_rules => template('role/labs/puppetmaster/extra_auth_rules.conf.erb'),
        config           => merge($encconfig, {
            'thin_storeconfigs' => false,
            'autosign'          => true,
        })
    }


    # Run a cron that pulls the ops/puppet repo & labs/private every minute.
    # We do not have equivalent of puppet merge for the labs puppetmaster
    cron { 'update_public_puppet_repos':
        ensure  => present,
        command => '(cd /var/lib/git/operations/puppet && /usr/bin/git pull && /usr/bin/git submodule update --init) > /dev/null 2>&1',
        user    => 'gitpuppet',
        minute  => '*/1',
    }

    cron { 'update_private_puppet_repos':
        ensure  => present,
        command => '(cd /var/lib/git/operations/labs/private && /usr/bin/git pull) > /dev/null 2>&1',
        user    => 'gitpuppet',
        minute  => '*/1',
    }

    include ::puppetmaster::certcleaner
    if ! defined(Class['puppetmaster::certmanager']) {
        class { 'puppetmaster::certmanager':
            remote_cert_cleaner => hiera('labs_certmanager_hostname'),
        }
    }
}
