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
#
# [*allow_from*]
#  Array of CIDRs from which to allow access to this puppetmaster.
#  Defaults to the entire 10.x range, so no real access control.
#
# [*git_sync_minutes*]
#  How frequently should the git repositories be sync'd to upstream.
#  Defaults to 10.
#
# [*extra_auth_rules*]
#  A string that gets added to auth.conf as extra auth rules for
#  the puppetmaster.
#
# [*server_name*]
#  Hostname for the puppetmaster. Defaults to fqdn. Is used for SSL
#  certificates, virtualhost routing, etc
#
# filtertags: labs-common
class role::puppetmaster::standalone(
    $autosign = false,
    $prevent_cherrypicks = false,
    $allow_from = ['10.0.0.0/8'],
    $git_sync_minutes = '10',
    $extra_auth_rules = '',
    $server_name = $::fqdn,
    $use_enc = true,
) {
    include ldap::role::config::labs

    $ldapconfig = $ldap::role::config::labs::ldapconfig
    $basedn = $ldapconfig['basedn']

    if $use_enc {
        include puppetmaster::enc
        $encconfig = $puppetmaster::enc::config
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
        server_name         => $server_name,
        allow_from          => $allow_from,
        secure_private      => false,
        include_conftool    => false,
        prevent_cherrypicks => $prevent_cherrypicks,
        extra_auth_rules    => $extra_auth_rules,
        config              => merge($encconfig, {
            'thin_storeconfigs' => false,
            'autosign'          => $autosign,
        }),
    }

    sslcert::ca { 'Puppetmaster_standalone_CA':
        source => '/var/lib/puppet/server/ssl/certs/ca.pem',
    }

    # Update git checkout
    class { 'puppetmaster::gitsync':
        run_every_minutes => $git_sync_minutes,
    }
}
