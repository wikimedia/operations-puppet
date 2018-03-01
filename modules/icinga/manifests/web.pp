# = Class: icinga::web
#
# Sets up an apache instance for icinga web interface,
# protected with ldap authentication
class icinga::web {
    include ::icinga

    # Apparently required for the web interface
    package { 'icinga-doc':
        ensure => present,
    }

    ferm::service { 'icinga-https':
      proto => 'tcp',
      port  => 443,
    }
    ferm::service { 'icinga-http':
      proto => 'tcp',
      port  => 80,
    }

    if os_version('debian >= stretch') {
        $php_gd_module = 'php7.0-gd'
    } else {
        $php_gd_module = 'php5-gd'
    }

    require_package($php_gd_module)

    include ::passwords::ldap::wmf_cluster
    $proxypass = $passwords::ldap::wmf_cluster::proxypass

    file { '/usr/share/icinga/htdocs/images/logos/ubuntu.png':
        source => 'puppet:///modules/icinga/ubuntu.png',
        owner  => 'icinga',
        group  => 'icinga',
        mode   => '0644',
    }

    # Allow up to 5 notes_url URLs
    ['1', '2', '3', '4', '5'].each |$note_id| {
        file { "/usr/share/icinga/htdocs/images/${note_id}-notes.gif":
            ensure => link,
            target => 'stats.gif',
        }
    }

    $ssl_settings = ssl_ciphersuite('apache', 'mid', true)

    letsencrypt::cert::integrated { 'icinga':
        subjects   => 'icinga.wikimedia.org',
        puppet_svc => 'apache2',
        system_svc => 'apache2',
    }

    httpd::site { 'icinga.wikimedia.org':
        content => template('icinga/icinga.wikimedia.org.erb'),
    }

    # remove icinga default config
    file { '/etc/icinga/apache2.conf':
        ensure => absent,
    }
    file { '/etc/apache2/conf.d/icinga.conf':
        ensure => absent,
    }

}
