# static HTML archive of old RT tickets (T180641)
class profile::microsites::static_rt(
    $ldap_config = lookup('ldap', Hash, hash, {}),
){

    backup::set { 'rt-static' : }
    ensure_resource('file', '/srv/org', {'ensure' => 'directory' })
    ensure_resource('file', '/srv/org/wikimedia', {'ensure' => 'directory' })
    ensure_resource('file', '/srv/org/wikimedia/static-rt', {'ensure' => 'directory' })

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

    #monitoring::service { 'static-rt-http':
    #    description   => 'Static RT HTTP',
    #    check_command => 'check_http_url!static-rt.wikimedia.org!/',
    #    notes_url     => 'https://wikitech.wikimedia.org/wiki/RT',
    #}

    rsync::quickdatacopy { 'srv-org-wikimedia-static-rt':
      ensure      => absent,
      auto_sync   => false,
      source_host => 'vega.codfw.wmnet',
      dest_host   => 'bromine.eqiad.wmnet',
      module_path => '/srv/org/wikimedia/static-rt',
    }
}
