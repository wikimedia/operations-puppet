
class wikitech::wiki::passwords {
    include passwords::wikitech
    include passwords::openstack::nova

    $wikitech_secret_key     = $passwords::wikitech::wikitech_secret_key
    $wikitech_upgrade_key    = $passwords::wikitech::wikitech_upgrade_key
    $wikitech_captcha_secret = $passwords::wikitech::wikitech_captcha_secret

    $wikitech_nova_ldap_proxyagent_pass = $passwords::openstack::nova::nova_ldap_proxyagent_pass
    $wikitech_nova_ldap_user_pass       = $passwords::openstack::nova::nova_ldap_user_pass

    # Drop this file onto the mediawiki deployment host so that the passwords are deployed
    file { '/srv/mediawiki/private/WikitechPrivateSettings.php':
        ensure  => present,
        content => template('wikitech/wikitech_private.php.erb'),
        mode    => '0444',
        owner   => 'mwdeploy',
        group   => 'mwdeploy',
    }

    file { '/srv/mediawiki/private/WikitechPrivateLdapSettings.php':
        ensure  => present,
        content => template('wikitech/wikitech_ldap.php.erb'),
        mode    => '0444',
        owner   => 'mwdeploy',
        group   => 'mwdeploy',
    }
}
