# ldap
#

class ldap::server::iptables-purges {

    require "iptables::tables"

    # The deny_all rule must always be purged, otherwise ACCEPTs can be placed below it
    iptables_purge_service{ "ldap_deny_all": service => "ldap" }
    iptables_purge_service{ "ldaps_deny_all": service => "ldaps" }

    # When removing or modifying a rule, place the old rule here, otherwise it won't
    # be purged, and will stay in the iptables forever

}

class ldap::server::iptables-accepts {

    require "ldap::server::iptables-purges"

    # Remember to place modified or removed rules into purges!
    iptables_add_service{ "ldap_server_corp": service => "ldap", source => "216.38.130.188", jump => "ACCEPT" }
    iptables_add_service{ "ldaps_server_corp": service => "ldaps", source => "216.38.130.188", jump => "ACCEPT" }
    iptables_add_service{ "ldaps_server_neon": service => "ldaps", source => "208.80.154.14", jump => "ACCEPT" }

}

class ldap::server::iptables-drops {

    require "ldap::server::iptables-accepts"

    iptables_add_service{ "ldap_server_deny_all": service => "ldap", jump => "DROP" }
    iptables_add_service{ "ldaps_server_deny_all": service => "ldaps", jump => "DROP" }

}

class ldap::server::iptables  {

    # We use the following requirement chain:
    # iptables -> iptables::drops -> iptables::accepts -> iptables::purges
    #
    # This ensures proper ordering of the rules
    require "ldap::server::iptables-drops"

    # This exec should always occur last in the requirement chain.
    iptables_add_exec{ "ldap_server": service => "ldap_server" }

}

class ldap::server( $certificate_location, $certificate, $ca_name, $cert_pass, $base_dn, $proxyagent, $proxyagent_pass, $server_bind_ips, $initial_password, $first_master=false ) {
    package { [ "openjdk-6-jre" ]:
        ensure => latest;
    }

    package { [ "opendj" ]:
        ensure => present,
        require => Package[ "openjdk-6-jre" ];
    }

    file {
        # Initial DIT
        '/etc/ldap/base.ldif':
            content => template("ldap/base.ldif.erb"),
            owner => opendj,
            group => opendj,
            mode => 0440,
            require => Package['ldap-utils', 'opendj'];
        # Changes global ACIs to set proper access controls
        '/etc/ldap/global-aci.ldif':
            source => "puppet:///modules/ldap/global-aci.ldif",
            owner => opendj,
            group => opendj,
            mode => 0440,
            require => Package['ldap-utils', 'opendj'];
        "$certificate_location":
            ensure => directory,
            require => Package['opendj'];
        '/etc/java-6-openjdk/security/java.security':
            source => "puppet:///modules/ldap/openjdk-6/java.security",
            owner => root,
            group => root,
            mode => 0444,
            require => Package['openjdk-6-jre'];
    }

    if ( $first_master == "true" ) {
        $create_ldap_db_command = "/usr/opendj/setup -i -b ${base_dn} -a -S -w ${initial_password} -O -n --noPropertiesFile --usePkcs12keyStore ${certificate_location}/${certificate}.p12 -W ${cert_pass} -Z 1636"
    } else {
        $create_ldap_db_command = "/usr/opendj/setup -i -b ${base_dn} -l /etc/ldap/base.ldif -S -w ${initial_password} -O -n --noPropertiesFile --usePkcs12keyStore ${certificate_location}/${certificate}.p12 -W ${cert_pass} -Z 1636"
    }

    exec {
        # Create an opendj instance with an initial DIT and SSL
        'create_ldap_db':
            unless => '/usr/bin/[ -d "/var/opendj/instance/db/userRoot" ]',
            user => "opendj",
            command => $create_ldap_db_command,
            # Ensure this occur befores the default file is put in place, since
            # changing the default file will schedule a service refresh. If the
            # service tries to start before an instance is created, it will create
            # an example userRoot, causing this to never run.
            before => File["/etc/default/opendj"],
            require => [Package["opendj"], File["${certificate_location}/${certificate}.p12"]];
        'start_opendj':
            subscribe => Exec['create_ldap_db'],
            refreshonly => true,
            command => "/etc/init.d/opendj start";
        # Create indexes for common attributes
        'create_indexes':
            subscribe => Exec['start_opendj'],
            refreshonly => true,
            user => "opendj",
            command => "/usr/opendj/bin/create-nis-indexes \"${base_dn}\" /var/tmp/indexes.cmds && /usr/opendj/bin/dsconfig -F /var/tmp/indexes.cmds --hostname ${fqdn} --port 4444 --trustStorePath /var/opendj/instance/config/admin-truststore --bindDN \"cn=Directory Manager\" --bindPassword ${initial_password} --no
-prompt; rm /var/tmp/indexes.cmds";
        # Rebuild the indexes
        'rebuild_indexes':
            subscribe => Exec['create_indexes'],
            refreshonly => true,
            command => "/etc/init.d/opendj stop; su - opendj -c '/usr/opendj/bin/rebuild-index --rebuildAll -b ${base_dn}'; /etc/init.d/opendj start";
        # Add the wmf CA to the opendj admin connector's truststore
        'add_ca_to_admintruststore':
            subscribe => Exec['start_opendj'],
            refreshonly => true,
            user => "opendj",
            command => "/usr/bin/keytool -importcert -trustcacerts -alias \"wmf-ca\" -file /etc/ssl/certs/wmf-ca.pem -keystore /var/opendj/instance/config/admin-truststore -storepass `cat /var/opendj/instance/config/admin-keystore.pin` -noprompt",
            require => Package['ca-certificates'];
        # Add the wmf CA to the opendj ssl truststore
        'add_ca_to_truststore':
            subscribe => Exec['start_opendj'],
            refreshonly => true,
            user => "opendj",
            command => "/usr/bin/keytool -importcert -trustcacerts -alias \"wmf-ca\" -file /etc/ssl/certs/wmf-ca.pem -keystore /var/opendj/instance/config/truststore -storepass `cat /var/opendj/instance/config/keystore.pin` -noprompt",
            require => Package['ca-certificates'];
        # Make the admin connector use the same pkcs12 file as ldaps config
        'fix_connector_cert_provider':
            subscribe => Exec['start_opendj'],
            refreshonly => true,
            user => "opendj",
            command => "/usr/opendj/bin/dsconfig set-administration-connector-prop --set key-manager-provider:PKCS12 --set ssl-cert-nickname:${certificate} --set trust-manager-provider:JKS --hostname ${fqdn} --port 4444 --trustStorePath /var/opendj/instance/config/admin-truststore --bindDN \"cn=Directory Manager\" --bindPassword ${initial_password} --no-prompt",
            require => Exec["add_ca_to_truststore", "add_ca_to_admintruststore"];
        # Enable starttls for ldap, using same pkcs12 file as ldaps config
        'enable_starttls':
            subscribe => Exec['start_opendj'],
            refreshonly => true,
            user => "opendj",
            command => "/usr/opendj/bin/dsconfig set-connection-handler-prop --handler-name \"LDAP Connection Handler\" --set allow-start-tls:true --set key-manager-provider:PKCS12 --set trust-manager-provider:JKS --hostname ${fqdn} --port 4444 --trustStorePath /var/opendj/instance/config/admin-truststore --bindDN \"cn=Directory Manager\" --bindPassword ${initial_password} --no-prompt",
            require => Exec["add_ca_to_truststore", "add_ca_to_admintruststore"];
        # Enable the uid unique attribute plugin
        'enable_uid_uniqueness_plugin':
            subscribe => Exec['start_opendj'],
            refreshonly => true,
            user => "opendj",
            command => "/usr/opendj/bin/dsconfig set-plugin-prop --plugin-name \"UID Unique Attribute\" --set enabled:true --add type:uidnumber --hostname ${fqdn} --port 4444 --trustStorePath /var/opendj/instance/config/admin-truststore --bindDN \"cn=Directory Manager\" --bindPassword ${initial_password} --no-prompt",
            require => Exec["add_ca_to_truststore", "add_ca_to_admintruststore"];
        # Enable referential integrity
        'enable_referential_integrity':
            subscribe => Exec['start_opendj'],
            refreshonly => true,
            user => "opendj",
            command => "/usr/opendj/bin/dsconfig set-plugin-prop --plugin-name \"Referential Integrity\" --set enabled:true --hostname ${fqdn} --port 4444 --trustStorePath /var/opendj/instance/config/admin-truststore --bindDN \"cn=Directory Manager\" --bindPassword ${initial_password} --no-prompt",
            require => Exec["add_ca_to_truststore", "add_ca_to_admintruststore"];
        # Modify the default global aci to fix access controls
        'modify_default_global_aci':
            subscribe => Exec['start_opendj'],
            refreshonly => true,
            command => "/usr/bin/ldapmodify -x -D 'cn=Directory Manager' -H ldap://${fqdn}:1389 -w ${initial_password} -f /etc/ldap/global-aci.ldif",
            require => [Package["ldap-utils"], File["/etc/ldap/global-aci.ldif"]];
    }

    file {
        "/usr/local/sbin/opendj-backup.sh":
            owner => root,
            group => root,
            mode  => 0555,
            require => Package["opendj"],
            source => "puppet:///modules/ldap/scripts/opendj-backup.sh";
        "/etc/default/opendj":
            owner => root,
            group => root,
            mode  => 0444,
            notify => Service["opendj"],
            require => Package["opendj"],
            content => template("ldap/opendj.default.erb");
    }

    cron {
        "opendj-backup":
            command =>  "/usr/local/sbin/opendj-backup.sh > /dev/null 2>&1",
            require =>  File["/usr/local/sbin/opendj-backup.sh"],
            user    =>  opendj,
            hour    =>  18,
            minute  =>  0;
    }

    service {
        "opendj":
            enable => true,
            ensure => running;
    }

    monitor_service { "ldap": description => "LDAP", check_command => "check_tcp!389" }
    monitor_service { "ldaps": description => "LDAPS", check_command => "check_tcp!636" }
    monitor_service { "ldap cert": description => "Certificate expiration", check_command => "check_cert!${fqdn}!636!${ca_name}", critical => "true" }

}

class ldap::server::schema::sudo {

    file {
        "/var/opendj/instance/config/schema/98-sudo.ldif":
            owner => opendj,
            group => opendj,
            mode  => 0444,
            require => Package["opendj"],
            source => "puppet:///modules/ldap/sudo.ldif";
    }

}

class ldap::server::schema::ssh {

    file {
        "/var/opendj/instance/config/schema/98-openssh-lpk.ldif":
            owner => opendj,
            group => opendj,
            mode  => 0444,
            require => Package["opendj"],
            source => "puppet:///modules/ldap/openssh-lpk.ldif";
    }

}

class ldap::server::schema::openstack {

    file {
        "/var/opendj/instance/config/schema/97-nova.ldif":
            owner => opendj,
            group => opendj,
            mode  => 0444,
            require => Package["opendj"],
            source => "puppet:///modules/ldap/nova_sun.ldif";
    }

}

class ldap::server::schema::puppet {

    file {
        "/var/opendj/instance/config/schema/98-puppet.ldif":
            owner => opendj,
            group => opendj,
            mode  => 0444,
            require => Package["opendj"],
            source => "puppet:///modules/ldap/puppet.ldif";
    }

}
