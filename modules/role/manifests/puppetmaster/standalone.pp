# = Class: role::puppetmaster::standalone
#
# Sets up a standalone puppetmaster, without frontend/backend
# separation.
#
# Useful only in labs.
#
# == Parameters
#
# [*autosign*]
#  Set to true to have puppetmaster automatically accept all
#  certificate signing requests. Note that if you want to
#  keep any secrets secure in your puppetmaster, you *can not*
#  use this, and will have to sign manually.
#
# [*prevent_cherrypicks*]
#  Set to true to prevent manual cherry-picking / modification of
#  the puppet git repository. Is accomplished using git hooks.
class role::puppetmaster::standalone(
    $autosign = false,
    $prevent_cherrypicks = false,
    $use_enc = true,
) {
    include ldap::role::config::labs

    $ldapconfig = $ldap::role::config::labs::ldapconfig
    $basedn = $ldapconfig['basedn']

    if $use_enc {
        # Setup ENC
        require_package('python3-yaml', 'python3-ldap3')

        include ldap::yamlcreds

        file { '/etc/puppet-enc.yaml':
            content => ordered_yaml({
                host => hiera('labs_puppet_master'),
            }),
            mode    => '0444',
            owner   => 'root',
            group   => 'root',
        }

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

    # Allow access from everywhere! Use certificates to
    # control access
    $allow_from = ['10.0.0.0/8']

    class { '::puppetmaster':
        server_name         => $::fqdn,
        allow_from          => $allow_from,
        secure_private      => false,
        include_conftool    => false,
        prevent_cherrypicks => $prevent_cherrypicks,,
        config              => merge($encconfig, {
            'thin_storeconfigs' => false,
            'autosign'          => $autosign,
        })
    }

    # Update git checkout
    include ::puppetmaster::gitsync
}
