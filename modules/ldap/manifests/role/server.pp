class ldap::role::server::labs {
    include ldap::role::config::labs,
        passwords::certs,
        passwords::ldap::initial_setup

    $certificate_location = '/var/opendj/instance'
    $cert_pass = $passwords::certs::certs_default_pass
    $initial_password = $passwords::ldap::initial_setup::initial_password

    $base_dn = $ldap::role::config::labs::ldapconfig['basedn']
    $domain = $ldap::role::config::labs::ldapconfig['domain']
    $proxyagent = $ldap::role::config::labs::ldapconfig['proxyagent']
    $proxypass = $ldap::role::config::labs::ldapconfig['proxypass']

    $certificate = $realm ? {
        'production' => 'star.wikimedia.org',
        'labs'       => 'star.wmflabs',
    }
    $ca_name = $realm ? {
        'production' => 'Equifax_Secure_CA.pem',
        'labs'       => 'wmf-labs.pem',
    }
    install_certificate{ $certificate: }
    # Add a pkcs12 file to be used for start_tls, ldaps, and opendj's admin connector.
    # Add it into the instance location, and ensure opendj can read it.
    create_pkcs12{ "${certificate}.opendj":
        certname => $certificate,
        user     => 'opendj',
        group    => 'opendj',
        location => $certificate_location,
        password => $cert_pass,
        require  => Package['opendj'],
    }

    include ldap::server::schema::sudo,
        ldap::server::schema::ssh,
        ldap::server::schema::openstack,
        ldap::server::schema::puppet

    class { 'ldap::server':
        certificate_location => $certificate_location,
        certificate          => $certificate,
        cert_pass            => $cert_pass,
        ca_name              => $ca_name,
        base_dn              => $base_dn,
        proxyagent           => $proxyagent,
        proxyagent_pass      => $proxypass,
        server_bind_ips      => "127.0.0.1 ${ipaddress_eth0}",
        initial_password     => $initial_password,
        first_master         => false,
    }

    if $realm == 'labs' {
        # server is on localhost
        file { '/var/opendj/.ldaprc':
            content => 'TLS_CHECKPEER   no TLS_REQCERT     never ',
            mode    => '0400',
            owner   => 'root',
            group   => 'root',
            require => Package['opendj'],
            before  => Exec['start_opendj'],
        }
    }
}

class ldap::role::server::production {
    include ldap::role::config::production,
        passwords::certs,
        passwords::ldap::initial_setup

    $certificate_location = '/var/opendj/instance'
    $cert_pass = $passwords::certs::certs_default_pass
    $initial_password = $passwords::ldap::initial_setup::initial_password

    $base_dn = $ldap::role::config::production::ldapconfig['basedn']
    $domain = $ldap::role::config::production::ldapconfig['domain']
    $proxyagent = $ldap::role::config::production::ldapconfig['proxyagent']
    $proxypass = $ldap::role::config::production::ldapconfig['proxypass']

    $certificate = "${hostname}.pmtpa.wmnet"
    $ca_name = 'wmf-ca.pem'
    install_certificate{ $certificate: }
    create_pkcs12{ "${certificate}.opendj":
        certname => $certificate,
        user     => 'opendj',
        group    => 'opendj',
        location => $certificate_location,
        password => $cert_pass,
    }

    include ldap::server::schema::sudo,
        ldap::server::schema::ssh,
        ldap::server::schema::openstack,
        ldap::server::schema::puppet

    class { 'ldap::server':
        certificate_location => $certificate_location,
        certificate          => $certificate,
        cert_pass            => $cert_pass,
        ca_name              => $ca_name,
        base_dn              => $base_dn,
        proxyagent           => $proxyagent,
        proxyagent_pass      => $proxypass,
        server_bind_ips      => "127.0.0.1 ${ipaddress_eth0}",
        initial_password     => $initial_password,
        first_master         => false,
    }
}

class ldap::role::server::corp {
    include ldap::role::config::corp,
        passwords::certs,
        passwords::ldap::initial_setup

    $certificate_location = '/var/opendj/instance'
    $cert_pass = $passwords::certs::certs_default_pass
    $initial_password = $passwords::ldap::initial_setup::initial_password

    $base_dn = $ldap::role::config::corp::ldapconfig['basedn']
    $domain = $ldap::role::config::corp::ldapconfig['domain']
    $proxyagent = $ldap::role::config::corp::ldapconfig['proxyagent']
    $proxypass = $ldap::role::config::corp::ldapconfig['proxypass']

    $certificate = $::fqdn
    $ca_name = 'wmf-ca.pem'
    install_certificate{ $certificate: }
    create_pkcs12{ "${certificate}.opendj":
        certname => $certificate,
        user     => 'opendj',
        group    => 'opendj',
        location => $certificate_location,
        password => $cert_pass,
    }

    class { 'ldap::server':
        certificate_location => $certificate_location,
        certificate          => $certificate,
        cert_pass            => $cert_pass,
        ca_name              => $ca_name,
        base_dn              => $base_dn,
        proxyagent           => $proxyagent,
        proxyagent_pass      => $proxypass,
        server_bind_ips      => "127.0.0.1 ${ipaddress_eth0}",
        initial_password     => $initial_password,
        first_master         => false,
    }
}
