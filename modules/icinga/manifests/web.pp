# = Class: icinga::web
#
# Sets up an apache instance for icinga web interface,
# protected with ldap authentication
class icinga::web {
    # Using require here is ok, because the icinga class is not parameterized.
    # if it was we would do Class['icinga'] -> Class['icinga::web'].
    require icinga

    # Apparently required for the web interface
    package { 'icinga-doc':
        ensure => latest
    }
    class {'webserver::php5': ssl => true,}

    ferm::service { 'icinga-https':
      proto => 'tcp',
      port  => 443,
    }
    ferm::service { 'icinga-http':
      proto => 'tcp',
      port  => 80,
    }

    include webserver::php5-gd

    include passwords::ldap::wmf_cluster
    $proxypass = $passwords::ldap::wmf_cluster::proxypass

    file { '/usr/share/icinga/htdocs/images/logos/ubuntu.png':
        source => 'puppet:///modules/icinga/ubuntu.png',
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
    }

    # install the Icinga Apache site
    apache::site { 'icinga.wikimedia.org':
        content => template('icinga/icinga.wikimedia.org.erb'),
    }

    # remove icinga default config
    file { '/etc/icinga/apache2.conf':
        ensure => absent,
    }
    file { '/etc/apache2/conf.d/icinga.conf':
        ensure => absent,
    }

    install_certificate{ 'icinga.wikimedia.org': ca => 'RapidSSL_CA.pem' }
    install_certificate{ 'icinga-admin.wikimedia.org': ca => 'RapidSSL_CA.pem' }

}
