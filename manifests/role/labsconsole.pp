#  Configure a labsconsole test instance:  Openstack, Mediawiki, Openstackmanager
#
#  Globals you will want to set:
#	$::mariadb = False
#	$::openstack_version = "essex"
#	$::dns_auth_ipaddress = "127.0.0.1"
#	$::dns_auth_soa_name = "wmflabs.org"
#	$::ldap_certificate = "star.wmflabs"
#	$::ldap_first_master = true
#	$::ldap_server_bind_ips = "127.0.0.1 10.4.0.82"

class role::labsconsole::labs {
	include passwords::openstack::nova

	$db_host = $realm ? {
		"production" => "virt0.wikimedia.org",
		"labs" => "localhost",
	}
	$ldap_server_primary = $realm ? {
		"production" => 'virt0.wikimedia.org',
		"labs" => 'localhost',
	}
	$ldap_server_secondary = $realm ? {
		"production" => 'virt1000.wikimedia.org',
		"labs" => 'localhost',
	}

    $wiki_name = "labsconsole-test"

    file { ["/var/www", "/var/www/srv", "/var/www/srv/org", "/var/www/srv/org/wikimedia", "/var/www/srv/org/wikimedia/controller", "/var/www/srv/org/wikimedia/controller/wikis", "/var/www/srv/org/wikimedia/controller/wikis/config"]:
        ensure => 'directory',
    }

	class { "mediawiki_singlenode":
		ensure => present,
		wiki_name => $wiki_name,
		mysql_pass => $passwords::openstack::nova::controller_mysql_root_pass,
        role_requires => [
        '\'/srv/org/wikimedia/controller/wikis/config/Settings.php\'',
        '\'/srv/org/wikimedia/controller/wikis/config/Private.php\'',
        '\'/srv/org/wikimedia/controller/wikis/config/Local.php\'',
        '\'/srv/org/wikimedia/controller/wikis/config/Debug.php\'',
        ],
		require => File["/var/www/srv/org/wikimedia/controller/wikis/config"],
		install_path => "/srv/org/wikimedia/controller/wikis/w";
	}

	mw-extension { [ "Echo", "CentralAuth", "Collection", "DynamicSidebar",
					"LdapAuthentication", "OATHAuth", "OpenStackManager",
					"SemanticForms", "SemanticMediaWiki", "SemanticResultFormats",
					"Validator", "WikiEditor", "CodeEditor", "Scribunto",
					"Renameuser", "SyntaxHighlight_GeSHi",
					"Cite", "Vector", "Gadgets", "CategoryTree", "ParserFunctions",
					"TitleBlacklist", "DataValues"]:
		ensure => present,
		install_path => "/srv/org/wikimedia/controller/wikis/w";
	}

    $host_address = $labs_mediawiki_hostname


	file {"/srv/org/wikimedia/controller/wikis/config":
            ensure => directory;
	}
	file {"/srv/org/wikimedia/controller/wikis/config/Settings.php":
		content => template("labsconsole/Settings.php.erb"),
		require => file["/srv/org/wikimedia/controller/wikis/config"],
		ensure => present;
	}
	file {"/srv/org/wikimedia/controller/wikis/config/Local.php":
		content => template("labsconsole/Local.php.erb"),
		require => file["/srv/org/wikimedia/controller/wikis/config"],
		ensure => present;
	}
	file {"/srv/org/wikimedia/controller/wikis/config/Debug.php":
		content => template("labsconsole/Debug.php.erb"),
		require => file["/srv/org/wikimedia/controller/wikis/config"],
		ensure => present;
	}
	file {"/srv/org/wikimedia/controller/wikis/config/Copy-to-Private.php":
		content => template("labsconsole/Private.php.erb"),
		require => file["/srv/org/wikimedia/controller/wikis/config"],
		ensure => present;
	}

	include role::ldap::server::labs, role::nova::compute, role::nova::controller
}
