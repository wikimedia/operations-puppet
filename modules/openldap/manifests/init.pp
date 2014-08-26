# Class: openldap
#
# This class installs slapd and configures it with a single suffix hdb database
#
# Parameters:
#    $server_id
#       This openLDAP server's ID. Mostly used in replication environments, but
#       generally good to have. An integer
#    $suffix
#       The suffix, e.g. "dc=example,dc=com"
#    $datadir
#       The datadir this suffix will be installed, e.g. "/var/lib/ldap"
#    $master
#       Optional. In a replication environment, the TLS-enabled master's fqdn
#    $sync_pass
#       Optional. In a replication environment, the password of the replication
#       user
#    $mirrormode
#       Optional, false by default. Whether the server will participate in a
#       dualmaster environment
#    $certificate
#       Optional. TLS enable the server. The path to the certificate file
#    $key
#       Optional. TLS enable the server. The path to the certificate file
#    $ca
#       Optional. TLS enable the server. The path to the CA certificate file
#
# Actions:
#       Install/configure slapd
#
# Requires:
#
# Sample Usage:
#       class { '::openldap':
#           server_id = 1,
#           suffix = 'dc=example,dc=org',
#           datadir = '/var/lib/ldap',
#       }
class openldap(
    $server_id,
    $suffix,
    $datadir,
    $master=undef,
    $sync_pass=undef,
    $mirrormode=false,
    $certificate=undef,
    $key=undef,
    $ca=undef,
) {

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

    # Mostly here to avoid unencrypted user initiated connections
    file { '/etc/ldap/ldap.conf':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('openldap/ldap.conf.erb'),
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
    Package['slapd'] -> File['/etc/ldap/schema/rfc2307bis.schema']
    Package['slapd'] -> File['/etc/ldap/schema/samba.schema']
    File['/etc/ldap/schema/rfc2307bis.schema'] -> Service['slapd']
    File['/etc/ldap/schema/samba.schema'] -> Service['slapd']
    File['/etc/ldap/ldap.conf'] -> Service['slapd']
}
