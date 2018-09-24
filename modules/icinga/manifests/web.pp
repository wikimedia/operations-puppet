# = Class: icinga::web
#
# Sets up an apache instance for icinga web interface,
# protected with ldap authentication
class icinga::web (
    $virtual_host,
    $icinga_user = 'icinga',
) {
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
        $php_version = '7.0'
    } else {
        $php_version = '5'
    }

    $php_gd_module = "php${php_version}-gd"
    $apache_php_package = "libapache2-mod-php${php_version}"

    require_package($apache_php_package, $php_gd_module)

    include ::passwords::ldap::wmf_cluster
    $proxypass = $passwords::ldap::wmf_cluster::proxypass

    file { '/usr/share/icinga/htdocs/images/logos/ubuntu.png':
        source => 'puppet:///modules/icinga/ubuntu.png',
        owner  => $icinga_user,
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
        subjects   => $virtual_host,
        puppet_svc => 'apache2',
        system_svc => 'apache2',
    }

    httpd::site { $virtual_host:
        content => template('icinga/apache.erb'),
    }

    # remove icinga default config
    file { '/etc/icinga/apache2.conf':
        ensure => absent,
    }
    file { '/etc/apache2/conf.d/icinga.conf':
        ensure => absent,
    }

}
