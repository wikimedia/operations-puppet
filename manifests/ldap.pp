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
	iptables_add_service{ "ldaps_server_spence": service => "ldaps", source => "208.80.152.161", jump => "ACCEPT" }
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
		ensure => "2.4.0-10",
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
			source => "puppet:///files/ldap/global-aci.ldif",
			owner => opendj,
			group => opendj,
			mode => 0440,
			require => Package['ldap-utils', 'opendj'];
		"$certificate_location":
			ensure => directory,
			require => Package['opendj'];
		'/etc/java-6-openjdk/security/java.security':
			source => "puppet:///files/openjdk-6/java.security",
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
			command => "/etc/init.d/opendj stop; su - opendj -c '/usr/opendj/bin/rebuild-index --rebuildAll -b ${ldap::server::config::base_dn}'; /etc/init.d/opendj start";				 
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
			source => "puppet:///files/ldap/scripts/opendj-backup.sh";
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
	monitor_service { "ldap cert": description => "Certificate expiration", check_command => "check_cert!${fqdn}!636!${ca_name}", critical => "true" }

}

class ldap::server::schema::sudo {

	file {
		"/var/opendj/instance/config/schema/98-sudo.ldif":
			owner => opendj,
			group => opendj,
			mode  => 0444,
			require => Package["opendj"],
			source => "puppet:///files/ldap/sudo.ldif";
	}

}

class ldap::server::schema::ssh {

	file {
		"/var/opendj/instance/config/schema/98-openssh-lpk.ldif":
			owner => opendj,
			group => opendj,
			mode  => 0444,
			require => Package["opendj"],
			source => "puppet:///files/ldap/openssh-lpk.ldif";
	}

}

class ldap::server::schema::openstack {

	file {
		"/var/opendj/instance/config/schema/97-nova.ldif":
			owner => opendj,
			group => opendj,
			mode  => 0444,
			require => Package["opendj"],
			source => "puppet:///files/ldap/nova_sun.ldif";
	}

}

class ldap::server::schema::puppet {

	file {
		"/var/opendj/instance/config/schema/98-puppet.ldif":
			owner => opendj,
			group => opendj,
			mode  => 0444,
			require => Package["opendj"],
			source => "puppet:///files/ldap/puppet.ldif";
	}

}

class ldap::client::pam($ldapconfig) {
	package { [ "libpam-ldapd" ]:
		ensure => latest;
	}

	File {
		owner => root,
		group => root,
		mode => 0444,
	}

	file {
		"/etc/pam.d/common-auth":
			source => "puppet:///files/ldap/common-auth";
		"/etc/pam.d/sshd":
			source => "puppet:///files/ldap/sshd";
		"/etc/pam.d/common-account":
			source => "puppet:///files/ldap/common-account";
		"/etc/pam.d/common-password":
			source => "puppet:///files/ldap/common-password";
		"/etc/pam.d/common-session":
			source => "puppet:///files/ldap/common-session";
		"/etc/pam.d/common-session-noninteractive":
			source => "puppet:///files/ldap/common-session-noninteractive";
	}
}

class ldap::client::nss($ldapconfig) {
	package { [ "libnss-ldapd", "nss-updatedb", "libnss-db", "nscd" ]:
		ensure => latest
	}
	package { [ "libnss-ldap" ]:
		ensure => purged;
	}

	service {
		nscd:
			subscribe => File["/etc/ldap/ldap.conf"],
			ensure => running;
		nslcd:
			ensure => running;
	}

	File {
		owner => root,
		group => root,
		mode => 0444,
	}

	file {
		"/etc/nscd.conf":
			notify => Service[nscd],
			source => "puppet:///files/ldap/nscd.conf";
		"/etc/nsswitch.conf":
			notify => Service[nscd],
			source => "puppet:///files/ldap/nsswitch.conf";
		"/etc/ldap.conf":
			notify => Service[nscd],
			content => template("ldap/nss_ldap.erb");
		"/etc/nslcd.conf":
			notify => Service[nslcd],
			mode => 0440,
			content => template("ldap/nslcd.conf.erb");
	}
}

# It is recommended that ldap::client:nss be included on systems that
# include ldap::client::utils, since some scripts use getent for ldap user info
# Remember though, that including ldap::client::nss will mean users in the
# ldap database will then be listed as users of the system, so use care.
class ldap::client::utils($ldapconfig) {
	include base::mwclient

	package { [ "python-ldap", "python-pycurl" ]:
		ensure => latest;
	}

	file {
		"/usr/local/sbin/add-ldap-user":
			owner => root,
			group => root,
			mode  => 0544,
			source => "puppet:///files/ldap/scripts/add-ldap-user";
		"/usr/local/sbin/add-labs-user":
			owner => root,
			group => root,
			mode  => 0544,
			source => "puppet:///files/ldap/scripts/add-labs-user";
		"/usr/local/sbin/modify-ldap-user":
			owner => root,
			group => root,
			mode  => 0544,
			source => "puppet:///files/ldap/scripts/modify-ldap-user";
		"/usr/local/sbin/delete-ldap-user":
			owner => root,
			group => root,
			mode  => 0544,
			source => "puppet:///files/ldap/scripts/delete-ldap-user";
		"/usr/local/sbin/add-ldap-group":
			owner => root,
			group => root,
			mode  => 0544,
			source => "puppet:///files/ldap/scripts/add-ldap-group";
		"/usr/local/sbin/modify-ldap-group":
			owner => root,
			group => root,
			mode  => 0544,
			source => "puppet:///files/ldap/scripts/modify-ldap-group";
		"/usr/local/sbin/delete-ldap-group":
			owner => root,
			group => root,
			mode  => 0544,
			source => "puppet:///files/ldap/scripts/delete-ldap-group";
		"/usr/local/sbin/netgroup-mod":
			owner => root,
			group => root,
			mode  => 0544,
			source => "puppet:///files/ldap/scripts/netgroup-mod";
		"/usr/local/sbin/ldaplist":
			owner => root,
			group => root,
			mode  => 0544,
			source => "puppet:///files/ldap/scripts/ldaplist";
		"/usr/local/sbin/change-ldap-passwd":
			owner => root,
			group => root,
			mode  => 0544,
			source => "puppet:///files/ldap/scripts/change-ldap-passwd";
		"/usr/local/sbin/homedirectorymanager.py":
			owner => root,
			group => root,
			mode  => 0544,
			source => "puppet:///files/ldap/scripts/homedirectorymanager.py";
		"/usr/local/sbin/manage-exports":
			owner => root,
			group => root,
			mode  => 0544,
			source => "puppet:///files/ldap/scripts/manage-exports";
		"/usr/local/sbin/manage-volumes-daemon":
			owner => root,
			group => root,
			mode  => 0544,
			source => "puppet:///files/ldap/scripts/manage-volumes-daemon";
		"/usr/local/sbin/manage-volumes":
			ensure => absent;
		"/usr/local/sbin/ldapsupportlib.py":
			owner => root,
			group => root,
			mode  => 0544,
			source => "puppet:///files/ldap/scripts/ldapsupportlib.py";
		"/usr/local/sbin/mail-instance-creator.py":
			owner => root,
			group => root,
			mode  => 0544,
			source => "puppet:///files/ldap/scripts/mail-instance-creator.py";
		"/etc/ldap/scriptconfig.py":
			owner => root,
			group => root,
			mode  => 0444,
			content => template("ldap/scriptconfig.py.erb");
	}

	if ( $realm != "labs" ) {
		file {
			"/etc/ldap/.ldapscriptrc":
				owner => root,
				group => root,
				mode  => 0700,
				content => template("ldap/ldapscriptrc.erb");
		}
	}
}

class ldap::client::sudo($ldapconfig) {
	package { [ "sudo-ldap" ]:
		ensure => latest;
	}
}

class ldap::client::openldap($ldapconfig) {
	package { [ "ldap-utils" ]:
		ensure => latest;
	}

	file {
		"/etc/ldap/ldap.conf":
			owner => root,
			group => root,
			mode  => 0444,
			content => template("ldap/open_ldap.erb");
	}
}

class ldap::client::autofs($ldapconfig) {
	# TODO: parametize this.
	if $realm == "labs" {
		$homedir_location = "/export/home/${instanceproject}"
		$nfs_server_name = $instanceproject ? {
			default => "labs-nfs1",
		}
		$gluster_server_name = $instanceproject ? {
			default => "projectstorage.pmtpa.wmnet",
		}
		$autofs_subscribe = ["/etc/ldap/ldap.conf", "/etc/ldap.conf", "/etc/nslcd.conf", "/data", "/public"]
	} else {
		$homedir_location = "/home"
		$nfs_server_name = "nfs-home.pmtpa.wmnet"
		$autofs_subscribe = ["/etc/ldap/ldap.conf", "/etc/ldap.conf", "/etc/nslcd.conf"]
	}

	package { [ "autofs5", "autofs5-ldap" ]:
		ensure => latest;
	}

	file {
		# autofs requires the permissions of this file to be 0600
		"/etc/autofs_ldap_auth.conf":
			owner => root,
			group => root,
			mode  => 0600,
			notify => Service[autofs],
			content => template("ldap/autofs_ldap_auth.erb");
		"/etc/default/autofs":
			owner => root,
			group => root,
			mode  => 0444,
			notify => Service[autofs],
			content => template("ldap/autofs.default.erb");
	}

	service { "autofs":
		enable => true,
		hasrestart => true,
		pattern => "automount",
		require => Package["autofs5", "autofs5-ldap", "ldap-utils", "libnss-ldapd" ],
		subscribe => File[$autofs_subscribe],
		ensure => running;
	}
}

class ldap::client::instance-finish {
	# Hacks to ensure these services are reloaded after the puppet run finishes
	if $realm == "labs" {
		exec { "check_nscd":
			command => "/etc/init.d/nscd restart",
			unless => "/usr/bin/id novaadmin";
		}

		exec { "check_autofs":
			command => "/etc/init.d/autofs restart",
			creates => "/home/autofs_check";
		}
	}
}

class ldap::client::includes($ldapincludes, $ldapconfig) {
	if "openldap" in $ldapincludes {
		class { "ldap::client::openldap":
			ldapconfig => $ldapconfig
		}
	}

	if "pam" in $ldapincludes {
		class { "ldap::client::pam":
			ldapconfig => $ldapconfig
		}
	} else {
		# The ldap nss package recommends this package
		# and this package will reconfigure pam as well as add
		# its support
		package { "libpam-ldapd":
			ensure => absent;
		}
	}

	if "nss" in $ldapincludes {
		class { "ldap::client::nss":
			ldapconfig => $ldapconfig
		}
	}

	if "sudo" in $ldapincludes {
		class { "ldap::client::sudo":
			ldapconfig => $ldapconfig
		}
	}

	if "autofs" in $ldapincludes {
		class { "ldap::client::autofs":
			ldapconfig => $ldapconfig
		}
	}

	if "utils" in $ldapincludes {
		class { "ldap::client::utils":
			ldapconfig => $ldapconfig
		}
	}

	if "access" in $ldapincludes {
		file { "/etc/security/access.conf":
			owner => root,
			group => root,
			mode  => 0444,
			content => template("ldap/access.conf.erb");
		}
	}

	if $realm == "labs" {
		if $managehome {
			$ircecho_logs = { "/var/log/manage-exports.log" => "#wikimedia-labs" }
			$ircecho_nick = "labs-home-wm"
			$ircecho_server = "irc.freenode.net"
	
			package { "ircecho":
				ensure => latest;
			}
	
			service { "ircecho":
				require => Package[ircecho],
				ensure => running;
			}
	
			file {
				"/etc/default/ircecho":
					require => Package[ircecho],
					content => template('ircecho/default.erb'),
					owner => root,
					mode => 0755;
			}

			cron { "manage-exports":
				command => "/usr/sbin/nscd -i passwd; /usr/sbin/nscd -i group; /usr/bin/python /usr/local/sbin/manage-exports --logfile=/var/log/manage-exports.log >/dev/null 2>&1",
				require => [ File["/usr/local/sbin/manage-exports"], Package["nscd"], Package["libnss-ldapd"], Package["ldap-utils"], File["/etc/ldap.conf"], File["/etc/ldap/ldap.conf"], File["/etc/nsswitch.conf"], File["/etc/nslcd.conf"] ];
			}
		} else {
			# This was added to all nodes accidentally
			cron { "manage-exports":
				ensure => absent;
			}
		}

		exec {
			"/usr/local/sbin/mail-instance-creator.py noc@wikimedia.org $instancecreator_email $instancecreator_lang https://wikitech.wikimedia.org/w/ && touch /var/lib/cloud/data/.usermailed":
			require => [ File['/usr/local/sbin/mail-instance-creator.py'], File['/etc/default/exim4'], Service['exim4'], Package['exim4-daemon-light'] ],
			creates => "/var/lib/cloud/data/.usermailed";
		}
	}
}
