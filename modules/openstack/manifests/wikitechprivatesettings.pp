# === Class openstack::wikitechprivatesettings
# Installs the private settings file for wikitech connection to ldap
class openstack::wikitechprivatesettings {
    $keystoneconfig = hiera_hash('keystoneconfig', {})

    $wikitech_nova_ldap_proxyagent_pass = $keystoneconfig['ldap_proxyagent_pass']
    $wikitech_nova_ldap_user_pass       = $keystoneconfig['ldap_user_pass']

    file { '/etc/mediawiki':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    # Drop this file onto the wikitech host; this file exists to hand off
    #  settings from private puppet to mediawiki.
    file { '/etc/mediawiki/WikitechPrivateSettings.php':
        ensure  => present,
        content => template('openstack/wikitech_private.php.erb'),
        mode    => '0644',
        owner   => 'root',
        group   => 'root',
    }
}
