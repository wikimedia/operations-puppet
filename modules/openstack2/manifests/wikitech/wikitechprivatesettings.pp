# === Class openstack::wikitechprivatesettings
# Installs the private settings file for wikitech connection to ldap
#
class openstack2::wikitech::wikitechprivatesettings(
    $wikitech_nova_ldap_proxyagent_pass,
    $wikitech_nova_ldap_user_pass,
    ) {

    file { '/etc/mediawiki':
        ensure => 'directory',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    # Drop this file onto the wikitech host; this file exists to hand off
    #  settings from private puppet to mediawiki.
    file { '/etc/mediawiki/WikitechPrivateSettings.php':
        ensure  => 'present',
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        content => template('openstack2/wikitech/wikitech_private.php.erb'),
    }
}
