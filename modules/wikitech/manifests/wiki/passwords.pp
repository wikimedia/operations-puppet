
class wikitech::wiki::passwords {
    include passwords::wikitech
    include passwords::openstack::nova

    $wikitech_db_password    = $passwords::wikitech::wikitech_db_password
    $wikitech_secret_key     = $passwords::wikitech::wikitech_secret_key
    $wikitech_upgrade_key    = $passwords::wikitech::wikitech_upgrade_key
    $wikitech_captcha_secret = $passwords::wikitech::wikitech_captcha_secret

    $wikitech_nova_ldap_proxyagent_pass = $passwords::openstack::nova::nova_ldap_proxyagent_pass
    $wikitech_nova_ldap_user_pass       = $passwords::openstack::nova::nova_ldap_user_pass

    # Drop this file onto the mediawiki deployment host so that the passwords are deployed
    file { '/a/common/private/WikitechPrivateSettings.php':
        ensure => present,
        content => template('wikitech/wikitech_private.php.erb'),
        mode   => '0444',
        owner  => 'root',
        group  => 'root',
    }

    file { '/a/common/private/WikitechPrivateLdapSettings.php':
        ensure => present,
        content => template('wikitech/wikitech_ldap.php.erb'),
        mode   => '0444',
        owner  => 'root',
        group  => 'root',
    }
}
