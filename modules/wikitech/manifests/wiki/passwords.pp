class wikitech::wiki::passwords {
    include passwords::openstack::nova

    $wikitech_nova_ldap_proxyagent_pass = $passwords::openstack::nova::nova_ldap_proxyagent_pass
    $wikitech_nova_ldap_user_pass       = $passwords::openstack::nova::nova_ldap_user_pass

    # Drop this file onto the mediawiki deployment host so that the passwords are deployed
    file { '/srv/mediawiki/private/WikitechPrivateLdapSettings.php':
        ensure  => present,
        content => template('wikitech/wikitech_ldap.php.erb'),
        mode    => '0444',
        owner   => 'mwdeploy',
        group   => 'mwdeploy',
    }
}
