# === Class deployment::wikitech
# Installs the private settings file for wikitech connection to ldap
class deployment::wikitech {
    $keystoneconfig = hiera_hash('keystoneconfig', {})

    $wikitech_nova_ldap_proxyagent_pass = $keystoneconfig['ldap_proxyagent_pass']
    $wikitech_nova_ldap_user_pass       = $keystoneconfig['ldap_user_pass']

    # Drop this file onto the mediawiki deployment host so that the passwords are deployed
    file { '/srv/mediawiki/private/WikitechPrivateLdapSettings.php':
        ensure  => present,
        content => template('deployment/wikitech_ldap.php.erb'),
        mode    => '0644',
        owner   => 'mwdeploy',
        group   => 'mwdeploy',
    }
}
