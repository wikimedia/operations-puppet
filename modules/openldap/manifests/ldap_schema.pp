define openldap::ldap_schema {
    file { "/etc/ldap/schema/${name}" :
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        source  => "puppet:///modules/openldap/${name}",
    }

    Package['slapd'] -> File["/etc/ldap/schema/${name}"]
    File["/etc/ldap/schema/${name}"] -> Service['slapd']
}
