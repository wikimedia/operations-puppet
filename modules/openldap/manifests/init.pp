#

class openldap {

    package { [
        'slapd',
        'ldap-utils',
        'python-ldap',
        ]:
        ensure => installed,
    }

    service { 'slapd':
        ensure     => running,
        hasstatus  => true,
        hasrestart => true,
    }

    # our replication dir
    file { '/var/lib/ldap/corp/':
        ensure  => directory,
        recurse => false,
        owner   => 'openldap',
        group   => 'openldap',
        mode    => '0750',
        force   => true,
    }

    file { '/etc/ldap/slapd.conf' :
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('openldap/slapd.erb'),
    }

    file { '/etc/default/slapd' :
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('openldap/default.erb'),
    }

    file { '/etc/ldap/schema/samba.schema' :
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        source  => 'puppet:///modules/openldap/samba.schema',
    }

    file { '/etc/ldap/schema/rfc2307bis.schema' :
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        source  => 'puppet:///modules/openldap/rfc2307bis.schema',
    }
    # We do this cause we want to rely on using slapd.conf for now
    exec { 'rm_slapd.d':
        onlyif  => '/usr/bin/test -d /etc/ldap/slapd.d',
        command => '/bin/rm -rf /etc/ldap/slapd.d',
    }

    # Relationships
    Package['slapd'] -> File['/etc/ldap/slapd.conf']
    Package['slapd'] -> File['/etc/default/slapd']
    Package['slapd'] -> File['/var/lib/ldap/corp/']
    Package['slapd'] -> Exec['rm_slapd.d']
    Exec['rm_slapd.d'] -> Service['slapd']
    File['/etc/ldap/slapd.conf'] ~> Service['slapd'] # We also notify
    File['/etc/default/slapd'] ~> Service['slapd'] # We also notify
    File['/var/lib/ldap/corp/'] -> Service['slapd']
    File['/etc/ldap/schema/rfc2307bis.schema'] -> Service['slapd']
    File['/etc/ldap/schema/samba.schema'] -> Service['slapd']
}
