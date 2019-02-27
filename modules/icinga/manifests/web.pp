# = Class: icinga::web
#
# Sets up an apache instance for icinga web interface,
# protected with ldap authentication
class icinga::web (
    String $icinga_user,
    String $icinga_group,
    String $virtual_host,
    String $apache2_htpasswd_salt,
    Hash[String, String] $apache2_auth_users,
) {

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

    include ::passwords::ldap::wmf_cluster
    $proxypass = $passwords::ldap::wmf_cluster::proxypass

    file { '/usr/share/icinga/htdocs/images/logos/ubuntu.png':
        source => 'puppet:///modules/icinga/ubuntu.png',
        owner  => $icinga_user,
        group  => $icinga_group,
        mode   => '0644',
    }

    # Allow up to 5 notes_url URLs
    ['1', '2', '3', '4', '5'].each |$note_id| {
        file { "/usr/share/icinga/htdocs/images/${note_id}-notes.gif":
            ensure => link,
            target => 'stats.gif',
        }
    }

    $ssl_settings = ssl_ciphersuite('apache', 'strong', true)

    acme_chief::cert { 'icinga':
        puppet_svc => 'apache2',
    }

    $auth_user_file = '/etc/icinga/apache2_auth_user_file'
    file { $auth_user_file:
        owner   => 'www-data',
        group   => 'www-data',
        mode    => '0440',
        content => template('icinga/apache2_auth_user_file.erb'),
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
