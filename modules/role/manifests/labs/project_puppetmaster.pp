# = Class: role::labs::project_puppetmasters
#
# Sets up a puppetmaster that can be used by all instances
# in a project. It mimics the labs puppetmaster in as many
# ways as possible.
class role::labs::project_puppetmaster(
    $autosign = false,
) {
    include ldap::role::config::labs

    $ldapconfig = $ldap::role::config::labs::ldapconfig
    $basedn = $ldapconfig['basedn']

    $encconfig = {
        'ldapserver'    => $ldapconfig['servernames'][0],
        'ldapbase'      => "ou=hosts,${basedn}",
        'ldapstring'    => '(&(objectclass=puppetClient)(associatedDomain=%s))',
        'ldapuser'      => $ldapconfig['proxyagent'],
        'ldappassword'  => $ldapconfig['proxypass'],
        'ldaptls'       => true,
        'node_terminus' => 'ldap'
    }

    # Allow access from everywhere! Use certificates to
    # control access
    $allow_from = ['10.0.0.0/8']

    class { '::puppetmaster':
        server_name    => $::fqdn,
        allow_from     => $allow_from,
        secure_private => false,
        config         => merge($encconfig, {
            'thin_storeconfigs' => false,
            'autosign'          => $autosign,
        })
    }
}
