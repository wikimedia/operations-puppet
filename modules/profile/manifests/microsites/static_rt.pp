# SPDX-License-Identifier: Apache-2.0
# static HTML archive of old RT tickets (T180641)
class profile::microsites::static_rt(
    Hash $ldap_config = lookup('ldap'),
){

    backup::set { 'rt-static' : }
    wmflib::dir::mkdir_p('/srv/org/wikimedia/static-rt')

    include ::passwords::ldap::production

    $ldap_url = "ldaps://${ldap_config[ro-server]} ${ldap_config[ro-server-fallback]}/ou=people,dc=wikimedia,dc=org?cn"
    $ldap_pass = $passwords::ldap::production::proxypass
    $ldap_group = 'cn=ops,ou=groups,dc=wikimedia,dc=org'

    file { '/srv/org/wikimedia/static-rt/index.html':
        ensure => present,
        owner  => 'www-data',
        group  => 'www-data',
        mode   => '0400',
        source => 'puppet:///modules/profile/microsites/static-rt-index.html';
    }

    httpd::site { 'static-rt.wikimedia.org':
        content  => template('profile/microsites/static-rt.wikimedia.org.erb'),
        priority => 20,
    }

    # TODO: enable once service is up
    #prometheus::blackbox::check::http { 'static-rt.wikimedia.org':
    #    team               => 'sre-collab',
    #    severity           => 'task',
    #    path               => '/',
    #    ip_families        => ['ip4'],
    #    force_tls          => true,
    #    body_regex_matches => ['RT'],
    #}
}
