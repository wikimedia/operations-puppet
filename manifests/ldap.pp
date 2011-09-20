# ldap
#

class ldap::server::iptables-purges {

	require "iptables::tables"

	# The deny_all rule must always be purged, otherwise ACCEPTs can be placed below it
	iptables_purge_service{ "${hostname}_ldap_deny_all": service => "ldap" }
	iptables_purge_service{ "${hostname}_ldaps_deny_all": service => "ldaps" }

	# When removing or modifying a rule, place the old rule here, otherwise it won't
	# be purged, and will stay in the iptables forever

}

class ldap::server::iptables-accepts {

	require "owa::database::iptables-purges"

	# Rememeber to place modified or removed rules into purges!
	iptables_add_service{ "${hostname}_ldap_server_corp": service => "ldap", source => "216.38.130.188", jump => "ACCEPT" }
	iptables_add_service{ "${hostname}_ldaps_server_corp": service => "ldaps", source => "216.38.130.188", jump => "ACCEPT" }
	iptables_add_service{ "${hostname}_ldaps_server_spence": service => "ldaps", source => "208.80.152.161", jump => "ACCEPT" }

}

class ldap::server::iptables-drops {

	require "ldap::server::iptables-accepts"

	iptables_add_service{ "${hostname}_ldap_server_deny_all": service => "ldap", jump => "DROP" }
	iptables_add_service{ "${hostname}_ldaps_server_deny_all": service => "ldaps", jump => "DROP" }

}

class ldap::server::iptables  {

	# We use the following requirement chain:
	# iptables -> iptables::drops -> iptables::accepts -> iptables::purges
	#
	# This ensures proper ordering of the rules
	require "ldap::server::iptables-drops"

	# This exec should always occur last in the requirement chain.
	iptables_add_exec{ "${hostname}_ldap_server": service => "ldap_server" }

}

class ldap::server( $ldap_certificate_location, $ldap_cert_pass, $ldap_base_dn ) {

	include passwords::ldap::initial_setup

	if $lsbdistcodename == "hardy" {

		exec {
			"/bin/echo \"sun-java6-bin shared/accepted-sun-dlj-v1-1 boolean true\" | /usr/bin/debconf-set-selections":
				alias => "debconf-set-selections-sun-java6-bin";

			"/bin/echo \"sun-java6-jre shared/accepted-sun-dlj-v1-1 boolean true\" | /usr/bin/debconf-set-selections":
				alias => "debconf-set-selections-sun-java6-jre";

		}

		package { [ "sun-java6-jre" ]:
			ensure => latest,
			require => Exec[ "debconf-set-selections-sun-java6-bin", "debconf-set-selections-sun-java6-jre" ];
		}

		package { [ "opendj" ]:
			ensure => "2.4.0-7",
			require => Package[ "sun-java6-jre" ];
		}

	} else {

		package { [ "openjdk-6-jre" ]:
			ensure => latest;
        	}

		package { [ "opendj" ]:
			ensure => "2.4.0-10",
			require => Package[ "openjdk-6-jre" ];
		}

	}

	if ( ! $ldap_server_bind_ips ) {
		$ldap_server_bind_ips = ""
	}

	file {
		# Initial DIT
		'/etc/ldap/base.ldif':
			content => template("ldap/base.ldif.erb"),
			owner => opendj,
			group => opendj,
			mode => 0640,
			require => Package['ldap-utils', 'opendj'];
		# Changes global ACIs to set proper access controls
		'/etc/ldap/global-aci.ldif':
			source => "puppet:///files/ldap/global-aci.ldif",
			owner => opendj,
			group => opendj,
			mode => 0640,
			require => Package['ldap-utils', 'opendj'];
		"$ldap_certificate_location":
			ensure => directory,
			require => Package['opendj'];
	}

	if ( ! $ldap_first_master ) {
		$ldap_first_master = "false"
	}

	if ( $ldap_first_master == "true" ) {
	        exec {
			# Create an opendj instance with an initial DIT and SSL
			'create_ldap_db':
				unless => '/usr/bin/[ -d "/var/opendj/instance/db/userRoot" ]',
				user => "opendj",
				command => "/usr/opendj/setup -i -b ${ldap_base_dn} -l /etc/ldap/base.ldif -S -w $passwords::ldap::initial_setup::ldap_initial_password -O -n --noPropertiesFile --usePkcs12keyStore ${ldap_certificate_location}/${ldap_certificate}.p12 -W ${ldap_cert_pass} -Z 1636",
				# Ensure this occur befores the default file is put in place, since
				# changing the default file will schedule a service refresh. If the
				# service tries to start before an instance is created, it will create
				# an example userRoot, causing this to never run.
				before => File["/etc/default/opendj"],                        
				require => [Package["opendj"], File["${ldap_certificate_location}/${ldap_certificate}.p12"]];
		}
	} else {
	        exec {
			# Create an opendj instance with an initial DIT and SSL
			'create_ldap_db':
				unless => '/usr/bin/[ -d "/var/opendj/instance/db/userRoot" ]',
				user => "opendj",
				command => "/usr/opendj/setup -i -b ${ldap_base_dn} -a -S -w $passwords::ldap::initial_setup::ldap_initial_password -O -n --noPropertiesFile --usePkcs12keyStore ${ldap_certificate_location}/${ldap_certificate}.p12 -W ${ldap_cert_pass} -Z 1636",
				# Ensure this occur befores the default file is put in place, since
				# changing the default file will schedule a service refresh. If the
				# service tries to start before an instance is created, it will create
				# an example userRoot, causing this to never run.
				before => File["/etc/default/opendj"],                        
				require => [Package["opendj"], File["${ldap_certificate_location}/${ldap_certificate}.p12"]];
		}
	}
        exec {
                'start_opendj':                        
			subscribe => Exec['create_ldap_db'],                        
			refreshonly => true,                        
			command => "/etc/init.d/opendj start";
                # Create indexes for common attributes
		'create_indexes':
                        subscribe => Exec['start_opendj'],
                        refreshonly => true,                        
			user => "opendj",                        
			command => "/usr/opendj/bin/create-nis-indexes \"${ldap_base_dn}\" /var/tmp/indexes.cmds && /usr/opendj/bin/dsconfig -F /var/tmp/indexes.cmds --hostname ${fqdn} --port 4444 --trustStorePath /var/opendj/instance/config/admin-truststore --bindDN \"cn=Directory Manager\" --bindPassword $passwords::ldap::initial_setup::ldap_initial_password --no
-prompt; rm /var/tmp/indexes.cmds";
                # Rebuild the indexes
                'rebuild_indexes':
                        subscribe => Exec['create_indexes'],
                        refreshonly => true,
                        command => "/etc/init.d/opendj stop; su - opendj -c '/usr/opendj/bin/rebuild-index --rebuildAll -b ${ldap::server::config::ldap_base_dn}'; /etc/init.d/opendj start";                
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
                        command => "/usr/opendj/bin/dsconfig set-administration-connector-prop --set key-manager-provider:PKCS12 --set ssl-cert-nickname:${ldap_certificate} --set trust-manager-provider:JKS --hostname ${fqdn} --port 4444 --trustStorePath /var/opendj/instance/config/admin-truststore --bindDN \"cn=Directory Manager\" --bindPassword $passwords::ldap::initial_setup::ldap_initial_password --no-prompt",
                        require => Exec["add_ca_to_truststore", "add_ca_to_admintruststore"];
                # Enable starttls for ldap, using same pkcs12 file as ldaps config
                'enable_starttls':
                        subscribe => Exec['start_opendj'],
                        refreshonly => true,                        
			user => "opendj",                        
			command => "/usr/opendj/bin/dsconfig set-connection-handler-prop --handler-name \"LDAP Connection Handler\" --set allow-start-tls:true --set key-manager-provider:PKCS12 --set trust-manager-provider:JKS --hostname ${fqdn} --port 4444 --trustStorePath /var/opendj/instance/config/admin-truststore --bindDN \"cn=Directory Manager\" --bindPassword $passwords::ldap::initial_setup::ldap_initial_password --no-prompt",
                        require => Exec["add_ca_to_truststore", "add_ca_to_admintruststore"];
                # Enable the uid unique attribute plugin
                'enable_uid_uniqueness_plugin':
                        subscribe => Exec['start_opendj'],
                        refreshonly => true,
                        user => "opendj",
                        command => "/usr/opendj/bin/dsconfig set-plugin-prop --plugin-name \"UID Unique Attribute\" --set enabled:true --add type:uidnumber --hostname ${fqdn} --port 4444 --trustStorePath /var/opendj/instance/config/admin-truststore --bindDN \"cn=Directory Manager\" --bindPassword $passwords::ldap::initial_setup::ldap_initial_password --no-prompt",
                        require => Exec["add_ca_to_truststore", "add_ca_to_admintruststore"];
                # Enable referential integrity
                'enable_referential_integrity':
                        subscribe => Exec['start_opendj'],
                        refreshonly => true,
                        user => "opendj",
                        command => "/usr/opendj/bin/dsconfig set-plugin-prop --plugin-name \"Referential Integrity\" --set enabled:true --hostname ${fqdn} --port 4444 --trustStorePath /var/opendj/instance/config/admin-truststore --bindDN \"cn=Directory Manager\" --bindPassword $passwords::ldap::initial_setup::ldap_initial_password --no-prompt",
                        require => Exec["add_ca_to_truststore", "add_ca_to_admintruststore"];
                # Modify the default global aci to fix access controls
                'modify_default_global_aci':
                        subscribe => Exec['start_opendj'],
                        refreshonly => true,
                        command => "/usr/bin/ldapmodify -x -D 'cn=Directory Manager' -H ldaps://${fqdn}:636 -w $passwords::ldap::initial_setup::ldap_initial_password -f /etc/ldap/global-aci.ldif",
                        require => [Package["ldap-utils"], File["/etc/ldap/global-aci.ldif"]];
        }

	file {
		"/usr/local/sbin/opendj-backup.sh":
			owner => root,
			group => root,
			mode  => 0755,
			require => Package["opendj"],
			source => "puppet:///files/ldap/scripts/opendj-backup.sh";
		"/etc/default/opendj":
			owner => root,
			group => root,
			mode  => 0644,
			notify => Service["opendj"],
			require => Package["opendj"],
			content => template("ldap/opendj.default.erb");
	}

	cron {
		"opendj-backup":
			command =>	"/usr/local/sbin/opendj-backup.sh > /dev/null 2>&1",
			require =>	File["/usr/local/sbin/opendj-backup.sh"],
			user	=>	opendj,
			hour	=>	18,
			minute	=>	0;
	}

	service {
		"opendj":
			enable => true,
			ensure => running;
	}

	monitor_service { "ldap": description => "LDAP", check_command => "check_tcp!389" }
	monitor_service { "ldaps": description => "LDAPS", check_command => "check_tcp!636" }

}

class ldap::server::wmf-cluster {

	include passwords::certs,
		passwords::ldap::wmf_cluster

	$ldap_user_dn = "cn=scriptuser,ou=profile,dc=wikimedia,dc=org"
	$ldap_user_pass = $passwords::ldap::wmf_cluster::ldap_user_pass 
        $ldap_cert_pass = $passwords::certs::certs_default_pass
	$ldap_certificate_location = "/var/opendj/instance"
	$ldap_base_dn = "dc=wikimedia,dc=org"
	$ldap_proxyagent = "cn=proxyagent,ou=profile,dc=corp,dc=wikimedia,dc=org"
	$ldap_proxyagent_pass = $passwords::ldap::wmf_cluster::ldap_proxyagent_pass
	$ldap_domain = "wikimedia"

	create_pkcs12{ "${ldap_certificate}.opendj": certname => "${ldap_certificate}", user => "opendj", group => "opendj", location => $ldap_certificate_location, password => $ldap_cert_pass } 

	include ldap::server::schema::sudo,
		ldap::server::schema::ssh,
		ldap::server::schema::openstack,
		ldap::server::schema::puppet

	class { "ldap::server":
		ldap_certificate_location => $ldap_certificate_location,
		ldap_cert_pass => $ldap_cert_pass,
		ldap_base_dn => $ldap_base_dn;
	}

}

class ldap::server::wmf-corp-cluster {

	include passwords::ldap::wmf_corp_cluster,
		passwords::certs

	$ldap_user_dn = "cn=scriptuser,ou=profile,dc=corp,dc=wikimedia,dc=org"
	$ldap_user_pass = $passwords::ldap::wmf_corp_cluster::ldap_user_pass
        $ldap_cert_pass = $passwords::certs::certs_default_pass
	$ldap_certificate_location = "/var/opendj/instance"
	$ldap_base_dn = "dc=corp,dc=wikimedia,dc=org"
	$ldap_proxyagent = "cn=proxyagent,ou=profile,dc=corp,dc=wikimedia,dc=org"
	$ldap_proxyagent_pass = $passwords::ldap::wmf_corp_cluster::ldap_proxyagent_pass
	$ldap_domain = "corp"

	create_pkcs12{ "${ldap_certificate}.opendj": certname => "${ldap_certificate}", user => "opendj", group => "opendj", location => $ldap_certificate_location, password => $ldap_cert_pass } 

	class { "ldap::server":
		ldap_certificate_location => $ldap_certificate_location,
		ldap_cert_pass => $ldap_cert_pass,
		ldap_base_dn => $ldap_base_dn;
	}

}

class ldap::server::schema::sudo {

	file {
		"/var/opendj/instance/config/schema/98-sudo.ldif":
			owner => opendj,
			group => opendj,
			mode  => 0644,
			require => Package["opendj"],
			source => "puppet:///files/ldap/sudo.ldif";
	}

}

class ldap::server::schema::ssh {

	file {
		"/var/opendj/instance/config/schema/98-openssh-lpk.ldif":
			owner => opendj,
			group => opendj,
			mode  => 0644,
			require => Package["opendj"],
			source => "puppet:///files/ldap/openssh-lpk.ldif";
	}

}

class ldap::server::schema::openstack {

	file {
		"/var/opendj/instance/config/schema/97-nova.ldif":
			owner => opendj,
			group => opendj,
			mode  => 0644,
			require => Package["opendj"],
			source => "puppet:///files/ldap/nova_sun.ldif";
	}

}

class ldap::server::schema::puppet {

	file {
		"/var/opendj/instance/config/schema/98-puppet.ldif":
			owner => opendj,
			group => opendj,
			mode  => 0644,
			require => Package["opendj"],
			source => "puppet:///files/ldap/puppet.ldif";
	}

}

class ldap::client::pam {

	package { [ "libpam-ldap" ]:
		ensure => latest;
	}

	file {
		"/etc/pam.d/common-auth":
			owner => root,
			group => root,
			mode  => 0644,
			source => "puppet:///files/ldap/common-auth";
		"/etc/pam.d/common-account":
			owner => root,
			group => root,
			mode  => 0644,
			source => "puppet:///files/ldap/common-account";
		"/etc/pam.d/common-password":
			owner => root,
			group => root,
			mode  => 0644,
			source => "puppet:///files/ldap/common-password";
		"/etc/pam.d/common-session":
			owner => root,
			group => root,
			mode  => 0644,
			source => "puppet:///files/ldap/common-session";
		"/etc/pam.d/common-session-noninteractive":
			owner => root,
			group => root,
			mode  => 0644,
			source => "puppet:///files/ldap/common-session-noninteractive";
	}
}

class ldap::client::nss {

	package { [ "libnss-ldap", "nss-updatedb", "libnss-db", "nscd" ]:
		ensure => latest
	}

	service {
		nscd:
			ensure  =>      running;
	}

	file {
		"/etc/nsswitch.conf":
			owner => root,
			group => root,
			mode  => 0644,
			source => "puppet:///files/ldap/nsswitch.conf";
		"/etc/ldap.conf":
			owner => root,
			group => root,
			mode  => 0644,
			content => template("ldap/nss_ldap.erb");
	}

}

# It is recommended that ldap::client:nss be included on systems that
# include ldap::client::utils, since some scripts use getent for ldap user info
# Remember though, that including ldap::client::nss will mean users in the
# ldap database will then be listed as users of the system, so use care.
class ldap::client::utils {

	include svn::client

	package { [ "python-ldap", "python-pycurl", "python-mwclient" ]:
		ensure => latest;
	}

	file {
		"/usr/local/sbin/add-ldap-user":
			ensure => link,
			target => "/usr/local/lib/user-management/add-ldap-user";
		"/usr/local/sbin/add-labs-user":
			ensure => link,
			target => "/usr/local/lib/user-management/add-labs-user";
		"/usr/local/sbin/modify-ldap-user":
			ensure => link,
			target => "/usr/local/lib/user-management/modify-ldap-user";
		"/usr/local/sbin/delete-ldap-user":
			ensure => link,
			target => "/usr/local/lib/user-management/delete-ldap-user";
		"/usr/local/sbin/add-ldap-group":
			ensure => link,
			target => "/usr/local/lib/user-management/add-ldap-group";
		"/usr/local/sbin/modify-ldap-group":
			ensure => link,
			target => "/usr/local/lib/user-management/modify-ldap-group";
		"/usr/local/sbin/delete-ldap-group":
			ensure => link,
			target => "/usr/local/lib/user-management/delete-ldap-group";
		"/usr/local/sbin/netgroup-mod":
			ensure => link,
			target => "/usr/local/lib/user-management/netgroup-mod";
		"/usr/local/sbin/ldaplist":
			ensure => link,
			target => "/usr/local/lib/user-management/ldaplist";
		"/usr/local/sbin/change-ldap-passwd":
			ensure => link,
			target => "/usr/local/lib/user-management/change-ldap-passwd";
		"/usr/local/sbin/homedirectorymanager.py":
			ensure => link,
			target => "/usr/local/lib/user-management/homedirectorymanager.py";
		"/usr/local/sbin/ldapsupportlib.py":
			ensure => link,
			target => "/usr/local/lib/user-management/ldapsupportlib.py";
		"/usr/local/sbin/mail-instance-creator.py":
			ensure => link,
			target => "/usr/local/lib/instance-management/mail-instance-creator.py";
		"/etc/ldap/scriptconfig.py":
			owner => root,
			group => root,
			mode  => 0644,
			content => template("ldap/scriptconfig.py.erb");
			
	}

	if ( $cluster_env != "labs" ) {
		file {
			"/etc/ldap/.ldapscriptrc":
				owner => root,
				group => root,
				mode  => 0700,
				content => template("ldap/ldapscriptrc.erb");
		}
	}

	# Use a specific revision for the checkout, to ensure we are using
	# a known and approved version of this script.
	exec { "checkout_user_ldap_tools":
		command => "/usr/bin/svn co -r96446 http://svn.wikimedia.org/svnroot/mediawiki/trunk/tools/subversion/user-management",
		cwd => "/usr/local/lib",
		require => Package["subversion"];
	}
	exec { "checkout_instance_ldap_tools":
		command => "/usr/bin/svn co -r97023 http://svn.wikimedia.org/svnroot/mediawiki/trunk/extensions/OpenStackManager/scripts/ instance-management",
		cwd => "/usr/local/lib",
		require => Package["subversion"];
	}

}

class ldap::client::sudo {

	package { [ "sudo-ldap" ]:
		ensure => latest;
	}

}

class ldap::client::openldap {

	package { [ "ldap-utils" ]:
		ensure => latest;
	}

	file {
		"/etc/ldap/ldap.conf":
			owner => root,
			group => root,
			mode  => 0644,
			content => template("ldap/open_ldap.erb");
	}
}

class ldap::client::autofs {

	package { [ "autofs5", "autofs5-ldap" ]:
		ensure => latest;
	}

	file {
		"/etc/autofs_ldap_auth.conf":
			owner => root,
			group => root,
			mode  => 0600,
			content => template("ldap/autofs_ldap_auth.erb");
	}
}

class ldap::client::wmf-cluster {

	include passwords::ldap::wmf_cluster

	$basedn = "dc=wikimedia,dc=org"
	$servernames = [ "nfs1.pmtpa.wmnet", "nfs2.pmtpa.wmnet" ]
	$proxypass = $passwords::ldap::wmf_cluster::proxypass
	$ldap_user_dn = "cn=scriptuser,ou=profile,dc=wikimedia,dc=org"
	$ldap_user_pass = $passwords::ldap::wmf_cluster::ldap_user_pass
	$ldap_ca = "wmf-ca.pem"
	$wikildapdomain = "labs"
	$wikicontrollerapiurl = "https://labsconsole.wikimedia.org/w/api.php"

	include ldap::client::includes,
		certificates::wmf_ca

}

class ldap::client::wmf-corp-cluster {

	include passwords::ldap::wmf_corp_cluster

	$basedn = "dc=corp,dc=wikimedia,dc=org"
	$servernames = [ "sanger.wikimedia.org" ]
	$proxypass = $passwords::ldap::wmf_corp_cluster::proxypass
	$ldap_user_dn = "cn=scriptuser,ou=profile,dc=corp,dc=wikimedia,dc=org"
	$ldap_user_pass = $passwords::ldap::wmf_corp_cluster::ldap_user_pass
	$ldap_ca = "wmf-ca.pem"

	include ldap::client::includes,
		certificates::wmf_ca

}

class ldap::client::wmf-test-cluster {

	include passwords::ldap::wmf_test_cluster

	$basedn = "dc=wikimedia,dc=org"
	$servernames = [ "virt1.wikimedia.org" ]
	$proxypass = $passwords::ldap::wmf_test_cluster::proxypass
	$ldap_ca = "Equifax_Secure_CA.pem"
	if ( $cluster_env == "labs" ) {
		$ldapincludes = ['openldap', 'pam', 'nss', 'sudo', 'autofs', 'utils', 'managehome']
	} else {
		$ldapincludes = ['openldap', 'utils']
	}
	$wikildapdomain = "labs"
	$wikicontrollerapiurl = "https://labsconsole.wikimedia.org/w/api.php"

	include ldap::client::includes,
		certificates::wmf_ca

}

class ldap::client::includes {

	if "openldap" in $ldapincludes {
		include ldap::client::openldap
	}

	if "pam" in $ldapincludes {
		include ldap::client::pam
	}

	if "nss" in $ldapincludes {
		include ldap::client::nss
	}

	if "sudo" in $ldapincludes {
		include ldap::client::sudo
	}

	if "autofs" in $ldapincludes {
		include ldap::client::autofs
	}

	if "utils" in $ldapincludes {
		include ldap::client::utils
	}

	if "managehome" in $ldapincludes {
		exec { "createhomedirs":
			command => "/etc/init.d/nscd restart; /usr/bin/python /usr/local/sbin/homedirectorymanager.py &>> /var/log/homedirectorymanager.log",
			require => [ File["/usr/local/sbin/homedirectorymanager.py"], Package["nscd"], Package["libnss-ldap"], Package["ldap-utils"], File["/etc/ssl/certs/wmf-tesla-ca.pem"], File["/etc/ldap.conf"], File["/etc/ldap/ldap.conf"], File["/etc/nsswitch.conf"] ];
		}
		if $cluster_env == "labs" {
			exec {
				"/usr/local/sbin/mail-instance-creator.py noc@wikimedia.org $instancecreator_email $instancecreator_lang http://nova-controller.tesla.usability.wikimedia.org/s-1/ && touch /var/lib/cloud/data/.usermailed":
				require => [ File['/usr/local/sbin/mail-instance-creator.py'], File['/etc/default/exim4'], Exec["createhomedirs"], Service['exim4'], Package['exim4-daemon-light'] ],
				creates => "/var/lib/cloud/data/.usermailed";
			}
		}
	}

}

class ldap::client::corp-server {

	$basedn = "dc=corp,dc=wikimedia,dc=org"
	$servernames = [ "sanger.wikimedia.org", "sfo-aaa1.corp.wikimedia.org" ]
	$ldap_ca = "wmf-ca.pem"

	include certificates::wmf_ca
	include ldap::client::openldap

}
