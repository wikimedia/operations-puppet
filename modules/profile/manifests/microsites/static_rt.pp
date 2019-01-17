# static HTML archive of old RT tickets (T180641)
class profile::microsites::static_rt {

    backup::set { 'rt-static' : }
    ensure_resource('file', '/srv/org', {'ensure' => 'directory' })
    ensure_resource('file', '/srv/org/wikimedia', {'ensure' => 'directory' })
    ensure_resource('file', '/srv/org/wikimedia/static-rt', {'ensure' => 'directory' })

    include ::passwords::ldap::wmf_cluster
    $proxypass = $passwords::ldap::wmf_cluster::proxypass

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
    #}

    rsync::quickdatacopy { 'srv-org-wikimedia-static-rt':
      ensure      => absent,
      auto_sync   => false,
      source_host => 'vega.codfw.wmnet',
      dest_host   => 'bromine.eqiad.wmnet',
      module_path => '/srv/org/wikimedia/static-rt',
    }
}
