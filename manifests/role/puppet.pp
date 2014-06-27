class role::puppet::server::labs {
    include role::nova::config
    $novaconfig = $role::nova::config::novaconfig

    $puppet_db_name = $novaconfig['puppet_db_name']
    $puppet_db_user = $novaconfig['puppet_db_user']
    $puppet_db_pass = $novaconfig['puppet_db_pass']

    $ldapconfig = $ldap::role::config::labs::ldapconfig
    $basedn = $ldapconfig['basedn']

    # Only allow puppet access from the instances
    $puppet_passenger_allow_from = $realm ? {
        'production' => [ '10.4.0.0/21', '10.68.16.0/21', '10.4.16.3', '10.64.20.8', '208.80.152.161', '208.80.154.14' ],
        'labs' => [ '192.168.0.0/21' ],
    }

    class { 'puppetmaster':
        server_name => $fqdn,
        allow_from  => $puppet_passenger_allow_from,
        config      => {
            'thin_storeconfigs' => false,
            'reports'           => 'labsstatus',
            # 'dbadapter' => "mysql",
            # 'dbuser' => $novaconfig["puppet_db_user"],
            # 'dbpassword' => $novaconfig["puppet_db_pass"],
            # 'dbserver' => $novaconfig["puppet_db_host"],
            'node_terminus'     => 'ldap',
            'ldapserver'        => $ldapconfig['servernames'][0],
            'ldapbase'          => "ou=hosts,${basedn}",
            'ldapstring'        => '(&(objectclass=puppetClient)(associatedDomain=%s))',
            'ldapuser'          => $ldapconfig['proxyagent'],
            'ldappassword'      => $ldapconfig['proxypass'],
            'ldaptls'           => true
        };
    }
}


# == Class role::puppet::self
# Wrapper class for puppet::self::master
# and puppet::self::client.
# If $::puppetmaster is localhost or matches the $::fqdn of this node,
# then this node will be configured as a puppetmaster.
# NOTE:  $::puppetmaster == 'localhost' (or undef) does the exact same
# thing as the original puppetmaster::self class used to do.
#
# $::puppetmaster must be set as a global variable.
# This allows puppet classes to be configured via LDAP
# and wikitech instance configuration.
#
class role::puppet::self {
    # If $::puppetmaster is not set, assume
    # this is a self hosted puppetmaster, not allowed
    # to serve any other puppet clients.
    $server = $::puppetmaster ? {
          undef       => 'localhost',
          'localhost' => 'localhost',
          ''          => 'localhost',
          # if has . characters in in, assume fqdn.
          /\./        => $::puppetmaster,
          # else assume short hostname and append domain.
          default     => "${::puppetmaster}.${::domain}",
    }

    # If localhost or if $server matches this node's
    # $fqdn, then this is a puppetmaster.
    if ($server == 'localhost' or $server == $::fqdn) {
        class { 'puppet::self::master':
            server => $server,
        }
    }
    # Else this is a puppet client.
    else {
        class { 'puppet::self::client':
            server => $server,
        }
    }
}
