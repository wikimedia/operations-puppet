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

    case $::realm {
        'labs': {
            $certificate = 'star.wmflabs'
            $ca_name = 'wmf-labs.pem'
        }
        'production': {
            case $::hostname {
                'nembus': {
                    $ca_name = 'GlobalSign_CA.pem'
                    $certificate = 'ldap-codfw.wikimedia.org'
                }
                'neptunium': {
                    $ca_name = 'GlobalSign_CA.pem'
                    $certificate = 'ldap-eqiad.wikimedia.org'
                }
                'default': {
                    fail('Production realm ldap certificates for nembus/neptunium only!')
                }
            }
        }
        'default': {
            fail('unknown realm, should be labs or production')
        }
    }

    install_certificate{ $certificate: ca => $ca_name }

    # Add a pkcs12 file to be used for start_tls, ldaps, and opendj's admin connector.
    # Add it into the instance location, and ensure opendj can read it.
    exec  { "${certificate}_pkcs12":
        creates => "${certificate_location}/${certificate}.p12",
        command => "/usr/bin/openssl pkcs12 -export -name \"${certificate}\" -passout pass:${cert_pass} -in /etc/ssl/localcerts/${certificate}.crt -inkey /etc/ssl/private/${certificate}.key -out ${certificate_location}/${certname}.p12",
        onlyif  => "/usr/bin/test -s /etc/ssl/private/${certificate}.key",
        require => [
            Package['openssl'],
            Package['opendj'],
            File["/etc/ssl/localcerts/${certname}.crt"],
            File["/etc/ssl/private/${certname}.key"],
        ],
    }
    file { "${certificate_location}/${certificate}.p12":
        ensure  => present,
        mode    => '0440',
        owner   => 'opendj',
        group   => 'opendj',
        require => Exec["${certificate}_pkcs12"],
    }

    include ldap::server::schema::sudo,
        ldap::server::schema::ssh,
        ldap::server::schema::openstack,
        ldap::server::schema::puppet

    class { 'ldap::server':
        certificate_location => $certificate_location,
        certificate          => $certificate,
        cert_pass            => $cert_pass,
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

    class { 'ldap::firewall':
        #  There are some repeats in this list, but as long as we're
        #   playing a shell game with the service domains, best to have
        #   everything listed here.
        server_list => ['ldap-eqiad.wikimedia.org',
                        'ldap-codfw.wikimedia.org',
                        'virt1000.wikimedia.org',
                        'labcontrol2001.wikimedia.org',
                        'neptunium.wikimedia.org']
    }
}
