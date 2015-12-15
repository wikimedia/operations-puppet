# ldap
#

class ldap::firewall( $server_list) {

    #  Allow admin communication between ldap servers
    ferm::service { 'ldap-admin':
        proto  => 'tcp',
        port   => '4444',
        srange => inline_template('(<%= @server_list.map{|x| "@resolve(#{x})" }.join(" ") %>)'),
    }

    #  Allow replication between ldap servers
    ferm::service { 'ldap-replication':
        proto  => 'tcp',
        port   => '8989',
        srange => inline_template('(<%= @server_list.map{|x| "@resolve(#{x})" }.join(" ") %>)'),
    }

    ferm::rule { 'ldap_private_labs':
        rule => 'saddr (10.0.0.0/8 208.80.152.0/22) daddr (10.0.0.0/8 208.80.152.0/22) proto tcp dport (ldap ldaps) ACCEPT;',
    }

    ferm::rule { 'ldap_backend_private_labs':
        rule => 'saddr (10.0.0.0/8 208.80.152.0/22) daddr (10.0.0.0/8 208.80.152.0/22) proto tcp dport (1389 1636) ACCEPT;',
    }
}

class ldap::server( $certificate_location, $certificate, $cert_pass, $base_dn, $proxyagent, $proxyagent_pass, $server_bind_ips, $initial_password, $first_master=false ) {
    package { 'openjdk-6-jre':
        ensure => latest,
    }

    package { 'opendj':
        ensure  => present,
        require => Package[ 'openjdk-6-jre' ],
    }
    # Initial DIT
    file { '/etc/ldap/base.ldif':
        content => template('ldap/base.ldif.erb'),
        owner   => 'opendj',
        group   => 'opendj',
        mode    => '0440',
        require => Package['ldap-utils', 'opendj'],
    }
        # Changes global ACIs to set proper access controls
    file { '/etc/ldap/global-aci.ldif':
        source  => 'puppet:///modules/ldap/global-aci.ldif',
        owner   => 'opendj',
        group   => 'opendj',
        mode    => '0440',
        require => Package['ldap-utils', 'opendj'],
    }

    file { $certificate_location:
        ensure  => directory,
        require => Package['opendj'],
    }

    file { '/etc/java-6-openjdk/security/java.security':
        source  => 'puppet:///modules/ldap/openjdk-6/java.security',
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        require => Package['openjdk-6-jre'],
    }

    if ( $first_master == true ) {
        $create_ldap_db_command = "/usr/opendj/setup -i -b ${base_dn} -a -S -w ${initial_password} -O -n --noPropertiesFile --usePkcs12keyStore ${certificate_location}/${certificate}.p12 -W ${cert_pass} -Z 1636"
    } else {
        $create_ldap_db_command = "/usr/opendj/setup -i -b ${base_dn} -l /etc/ldap/base.ldif -S -w ${initial_password} -O -n --noPropertiesFile --usePkcs12keyStore ${certificate_location}/${certificate}.p12 -W ${cert_pass} -Z 1636"
    }
    # Create an opendj instance with an initial DIT and SSL
    exec { 'create_ldap_db':
        unless  => '/usr/bin/[ -d "/var/opendj/instance/db/userRoot" ]',
        user    => 'opendj',
        command => $create_ldap_db_command,
        # Ensure this occur befores the default file is put in place, since
        # changing the default file will schedule a service refresh. If the
        # service tries to start before an instance is created, it will create
        # an example userRoot, causing this to never run.
        before  => File['/etc/default/opendj'],
        require => [Package['opendj'],
                    File["${certificate_location}/${certificate}.p12"]],
    }

    exec { 'start_opendj':
        subscribe   => Exec['create_ldap_db'],
        refreshonly => true,
        command     => '/etc/init.d/opendj start',
    }
    # Create indexes for common attributes
    exec { 'create_indexes':
        subscribe   => Exec['start_opendj'],
        refreshonly => true,
        user        => 'opendj',
        command     => "/usr/opendj/bin/create-nis-indexes \'${base_dn}\' /var/tmp/indexes.cmds && /usr/opendj/bin/dsconfig -F /var/tmp/indexes.cmds --hostname ${fqdn} --port 4444 --trustStorePath /var/opendj/instance/config/admin-truststore --bindDN \'cn=Directory Manager\' --bindPassword ${initial_password} --no -prompt; rm /var/tmp/indexes.cmds",
    }
    # Rebuild the indexes
    exec { 'rebuild_indexes':
        subscribe   => Exec['create_indexes'],
        refreshonly => true,
        command     => "/etc/init.d/opendj stop; su - opendj -c '/usr/opendj/bin/rebuild-index --rebuildAll -b ${base_dn}'; /etc/init.d/opendj start",
    }
    # Make the admin connector use the same pkcs12 file as ldaps config
    exec { 'fix_connector_cert_provider':
        subscribe   => Exec['start_opendj'],
        refreshonly => true,
        user        => 'opendj',
        command     => "/usr/opendj/bin/dsconfig
set-administration-connector-prop --set key-manager-provider:PKCS12 --set ssl-cert-nickname:${certificate} --set trust-manager-provider:JKS --hostname ${fqdn} --port 4444 --trustStorePath /var/opendj/instance/config/admin-truststore --bindDN \'cn=Directory Manager\' --bindPassword ${initial_password} --no-prompt",
    }
    # Enable starttls for ldap, using same pkcs12 file as ldaps config
    exec { 'enable_starttls':
        subscribe   => Exec['start_opendj'],
        refreshonly => true,
        user        => 'opendj',
        command     => "/usr/opendj/bin/dsconfig set-connection-handler-prop --handler-name \'LDAP Connection Handler\' --set allow-start-tls:true --set key-manager-provider:PKCS12 --set trust-manager-provider:JKS --hostname ${fqdn} --port 4444 --trustStorePath /var/opendj/instance/config/admin-truststore --bindDN \'cn=Directory Manager\' --bindPassword ${initial_password} --no-prompt",
    }
    # Enable the uid unique attribute plugin
    exec { 'enable_uid_uniqueness_plugin':
        subscribe   => Exec['start_opendj'],
        refreshonly => true,
        user        => 'opendj',
        command     => "/usr/opendj/bin/dsconfig set-plugin-prop --plugin-name \'UID Unique Attribute\' --set enabled:true --add type:uidnumber --hostname ${fqdn} --port 4444 --trustStorePath /var/opendj/instance/config/admin-truststore --bindDN \'cn=Directory Manager\' --bindPassword ${initial_password} --no-prompt",
    }
    # Enable referential integrity
    exec { 'enable_referential_integrity':
        subscribe   => Exec['start_opendj'],
        refreshonly => true,
        user        => 'opendj',
        command     => "/usr/opendj/bin/dsconfig set-plugin-prop --plugin-name \'Referential Integrity\' --set enabled:true --hostname ${fqdn} --port 4444 --trustStorePath /var/opendj/instance/config/admin-truststore --bindDN \'cn=Directory Manager\' --bindPassword ${initial_password} --no-prompt",
    }
    # Modify the default global aci to fix access controls
    exec { 'modify_default_global_aci':
        subscribe   => Exec['start_opendj'],
        refreshonly => true,
        command     => "/usr/bin/ldapmodify -x -D 'cn=Directory Manager' -H ldap://${fqdn}:1389 -w ${initial_password} -f /etc/ldap/global-aci.ldif",
        require     => [Package['ldap-utils'],
                        File['/etc/ldap/global-aci.ldif']],
    }

    file { '/usr/local/sbin/opendj-backup.sh':
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
        require => Package['opendj'],
        source  => 'puppet:///modules/ldap/scripts/opendj-backup.sh',
    }

    file { '/etc/default/opendj':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        notify  => Service['opendj'],
        require => Package['opendj'],
        content => template('ldap/opendj.default.erb'),
    }

    cron { 'opendj-backup':
        command =>  '/usr/local/sbin/opendj-backup.sh > /dev/null 2>&1',
        require =>  File['/usr/local/sbin/opendj-backup.sh'],
        user    =>  'opendj',
        hour    =>  18,
        minute  =>  0,
    }

    service { 'opendj':
        ensure => stopped,
        enable => true,
    }

    monitoring::service { 'ldap': description      => 'LDAP', check_command                   => 'check_tcp!389' }
    monitoring::service { 'ldaps': description     => 'LDAPS', check_command                  => 'check_tcp!636' }

    # TODO: make this critical (paging) again once confirmed fixed
    monitoring::service { 'ldap cert':
        description   => 'Certificate expiration',
        check_command => "check_ssl_ldap!${certificate}",
        critical      => false
    }

}

class ldap::server::schema::sudo {

    file { '/var/opendj/instance/config/schema/98-sudo.ldif':
        owner   => 'opendj',
        group   => 'opendj',
        mode    => '0444',
        require => Package['opendj'],
        source  => 'puppet:///modules/ldap/sudo.ldif',
    }

}

class ldap::server::schema::ssh {

    file { '/var/opendj/instance/config/schema/98-openssh-lpk.ldif':
        owner   => 'opendj',
        group   => 'opendj',
        mode    => '0444',
        require => Package['opendj'],
        source  => 'puppet:///modules/ldap/openssh-lpk.ldif',
    }

}

class ldap::server::schema::openstack {

    file { '/var/opendj/instance/config/schema/97-nova.ldif':
        owner   => 'opendj',
        group   => 'opendj',
        mode    => '0444',
        require => Package['opendj'],
        source  => 'puppet:///modules/ldap/nova_sun.ldif',
    }

}

class ldap::server::schema::openstack {

    file { '/var/opendj/instance/config/schema/99-user.ldif':
        owner   => 'opendj',
        group   => 'opendj',
        mode    => '0444',
        require => Package['opendj'],
        source  => 'puppet:///modules/ldap/user.ldif',
    }

}

class ldap::server::schema::openstack {

    file { '/var/opendj/instance/config/schema/80-dnsdomain2.ldif':
        owner   => 'opendj',
        group   => 'opendj',
        mode    => '0444',
        require => Package['opendj'],
        source  => 'puppet:///modules/ldap/dnsdomain2.ldif',
    }

}

class ldap::server::schema::puppet {

    file { '/var/opendj/instance/config/schema/98-puppet.ldif':
        owner   => 'opendj',
        group   => 'opendj',
        mode    => '0444',
        require => Package['opendj'],
        source  => 'puppet:///modules/ldap/puppet.ldif',
    }
}
