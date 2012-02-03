# site.pp

import "realm.pp"	# These ones first
import "generic-definitions.pp"
import "base.pp"

import "admins.pp"
import "apaches.pp"
import "backups.pp"
import "certs.pp"
import "dns.pp"
import "drac.pp"
import "facilities.pp"
import "ganglia.pp"
import "gerrit.pp"
import "imagescaler.pp"
import "iptables.pp"
import "jobrunner.pp"
import "ldap.pp"
import "lvs.pp"
import "mail.pp"
import "media-storage.pp"
import "mediawiki.pp"
import "memcached.pp"
import "misc/*.pp"
import "misc-servers.pp"
import "mysql.pp"
import "nagios.pp"
import "network.pp"
import "nfs.pp"
import "nrpe.pp"
import "ntp.pp"
import "openstack.pp"
import "owa.pp"
import "protoproxy.pp"
import "puppetmaster.pp"
import "role/*.pp"
import "search.pp"
import "snapshots.pp"
import "squid.pp"
import "svn.pp"
import "swift.pp"
import "varnish.pp"
import "webserver.pp"

# Include stages last
import "stages.pp"

# Initialization

# Base nodes

# Class for *most* servers, standard includes
class standard {
	include base,
		ganglia,
		ntp::client,
		exim::simple-mail-sender
}

#############################
# Role classes
#############################

# TODO: Perhaps rename these classes to "role::<class>" to distinguish them
# from classes inside service manifests
# Update: migration is now in progress, into role/<class>.pp. Classes still here
# are old, and probably need to be rewritten.


# TODO: rewrite this old mess.
class applicationserver {
	class parent {
		$cluster = "appserver"
		$nagios_group = $cluster
	}

	class homeless inherits parent {
		$lvs_realserver_ips = $realm ? {
			'production' => [ "10.2.1.1" ],
			'labs' => [ "10.4.0.254" ],
		}

		include	standard,
			admins::roots,
			admins::mortals,
			accounts::l10nupdate,
			nfs::upload,
			mediawiki::packages,
			lvs::realserver,
			apaches::cron,
			apaches::service,
			apaches::pybal-check,
			apaches::monitoring,
			generic::geoip::files
	}

	class home-no-service inherits parent {
		include	standard,
			nfs::home,
			nfs::upload,
			mediawiki::packages,
			admins::roots,
			admins::mortals,
			accounts::l10nupdate,
			generic::geoip::files
	}

	class home inherits home-no-service {
		include apaches::service,
			apaches::pybal-check
	}

	class api inherits parent {
		$cluster = "api_appserver"
		$nagios_group = $cluster

		$lvs_realserver_ips = $realm ? {
			'production' => [ "10.2.1.22", "10.2.1.1" ],
			'labs' => [ "10.4.0.253" ],
		}

		include standard,
			admins::roots,
			admins::mortals,
			accounts::l10nupdate,
			nfs::upload,
			lvs::realserver,
			mediawiki::packages,
			apaches::cron,
			apaches::service,
			apaches::pybal-check,
			apaches::monitoring,
			generic::geoip::files
	}

	class bits inherits parent {
		$cluster = "bits_appserver"
		$nagios_group = $cluster

		$lvs_realserver_ips = $realm ? {
			'production' => [ "10.2.1.1" ],
			'labs' => [ "10.4.0.252" ],
		}

		include standard,
			admins::roots,
			admins::mortals,
			accounts::l10nupdate,
			mediawiki::packages,
			lvs::realserver,
			apaches::cron,
			apaches::service,
			apaches::pybal-check,
			apaches::monitoring,
			generic::geoip::files
	}

	class jobrunner {
		include jobrunner::packages
	}

}

class imagescaler {
	$cluster = "imagescaler"
	$nagios_group = "image_scalers"

	$lvs_realserver_ips = $realm ? {
		'production' => [ "10.2.1.21" ],
		'labs' => [ "10.4.0.252" ],
	}

	include standard,
		imagescaler::cron,
		imagescaler::packages,
		imagescaler::files,
		nfs::upload,
		mediawiki::packages,
		lvs::realserver,
		apaches::packages,
		apaches::cron,
		apaches::service,
		admins::roots,
		admins::mortals,
		admins::restricted,
		apaches::pybal-check,
		apaches::monitoring,
		accounts::l10nupdate
}

class db::core {
	$cluster = "mysql"

	system_role { "db::core": description => "Core Database server" }

	include standard,
		mysql
}

class db::es {
	$cluster = "mysql"

	$nagios_group = "es"

	system_role { "db::es": description => "External Storage server (${mysql_role})" }

	include	standard,
		mysql,
		mysql::mysqluser,
		mysql::datadirs,
		mysql::conf,
		mysql::mysqlpath,
		nrpe

	# Nagios monitoring
	monitor_service {
		"mysql status":
			description => "MySQL ${mysql_role} status",
			check_command => "check_mysqlstatus!--${mysql_role}";
		"mysql replication":
			description => "MySQL replication status",
			check_command => "check_db_lag",
			ensure => $mysql_role ? {
				"master" => absent,
				"slave" => present
			};
	}

}

class db::es::master {
	$mysql_role = "master"
	include db::es
}

class db::es::slave {
	$mysql_role = "slave"
	include db::es
}

class searchserver {
	$cluster = "search"
	$nagios_group = "lucene"

	$lvs_realserver_ips = [ "10.2.1.11", "10.2.1.12", "10.2.1.13" ]

	include	standard,
		nfs::home,
		admins::roots,
		admins::mortals,
		admins::restricted,
		search::sudo,
		search::jvm,
		search::monitoring,
		lvs::realserver
}

class searchindexer {
	$cluster = "search"
	$nagios_group = "lucene"

	$search_indexer = "true"

	include	standard,
		admins::roots,
		admins::mortals,
		admins::restricted,
		search::sudo,
		search::jvm,
		search::php,
		search::monitoring,
		search::indexer
}

class protoproxy::ssl {
	$cluster = "ssl"

	if $hostname =~ /^ssl(300)?1$/ {
		$enable_ipv6_proxy = true
	}

	include standard,
		certificates::wmf_ca,
		protoproxy::proxy_sites

	monitor_service { "https": description => "HTTPS", check_command => "check_ssl_cert!*.wikimedia.org" }
}


# Default variables
$cluster = "misc"

# FIXME: move to realm.pp
# FIXME: check if this is still correct, this was temp for a migration
$dns_auth_master = "ns1.wikimedia.org"

# Node definitions (alphabetic order)

node "alsted.wikimedia.org" {

	include base,
		admins::roots
}

node /amslvs[1-4]\.esams\.wikimedia\.org/ {
	$lvs_balancer_ips = [ "91.198.174.232", "91.198.174.233", "91.198.174.234", "91.198.174.224", "91.198.174.225", "91.198.174.226", "91.198.174.227", "91.198.174.228", "91.198.174.229", "91.198.174.230", "91.198.174.231", "91.198.174.235", "10.2.3.23", "10.2.3.24", "10.2.3.25" ]

	# PyBal is very dependent on recursive DNS, to the point where it is a SPOF
	# So we'll have every LVS server run their own recursor
	$nameservers = [ $ipaddress, "91.198.174.6", "208.80.152.131" ]
	$dns_recursor_ipaddress = $ipaddress

	include base,
		ganglia,
		dns::recursor,
		lvs::balancer
}

# amssq31-46 are text squids
node /amssq(3[1-9]|4[0-6])\.esams\.wikimedia\.org/ {
	$squid_coss_disks = [ 'sda5', 'sdb5' ]
	if $hostname =~ /^amssq3[12]$/ {
		$ganglia_aggregator = "true"
	}

	include role::cache::text
}

node /amssq(4[7-9]|5[0-9]|6[0-2])\.esams\.wikimedia\.org/ {
	$squid_coss_disks = [ 'sdb5' ]

	include role::cache::upload
}

node "argon.wikimedia.org" {
	$cluster = "misc"
	include base,
		ganglia,
		certificates::star_wikimedia_org,
		ntp::client,
		misc::survey

	install_certificate{ "star.wikimedia.org": }
	monitor_service { "secure cert": description => "Certificate expiration", check_command => "check_cert!secure.wikimedia.org!443!Equifax_Secure_CA.pem", critical => "true" }
}

node /(arsenic|niobium)\.wikimedia\.org/ {
	$ganglia_aggregator = "true"

	interface_aggregate { "bond0": orig_interface => "eth0", members => [ "eth0", "eth1", "eth2", "eth3" ] }

	include role::cache::bits
}

node "bayes.wikimedia.org" {
	include standard,
		admins::roots,
		accounts::ezachte,
		accounts::reedy,
		accounts::nimishg,
		accounts::diederik
}

node "bast1001.wikimedia.org" {
	$cluster = "misc"
	$domain_search = "wikimedia.org pmtpa.wmnet eqiad.wmnet esams.wikimedia.org"

	include standard,
		svn::client,
		admins::roots,
		admins::mortals,
		admins::restricted,
		misc::bastionhost,
		misc::scripts,
		nrpe
}

node "brewster.wikimedia.org" {

	$tftpboot_server_type = 'master'

	include standard,
		misc::install-server,
		backup::client
}

node "carbon.wikimedia.org" {
	include standard,
		backup::client,
		misc::install-server::tftp-server
}

node /^(copper|zinc)\.wikimedia\.org$/ {
	$ganglia_aggregator = "true"

	include role::swift::eqiad-test
}

node /^cp10(0[1-9]|1[0-9]|20)\.eqiad\.wmnet$/ {
	$squid_coss_disks = [ 'sda5', 'sdb5' ]
	if $hostname =~ /^cp100(1|2)$/ {
		$ganglia_aggregator = "true"
	}

	include role::cache::text
}

# eqiad varnish for m.wikipedia.org
node /cp104[1-4].wikimedia.org/ {

	if $hostname =~ /^cp104(3|4)$/ {
		$ganglia_aggregator = "true"
	}

	include role::cache::mobile
}

node /^cp300[12]\.esams\.wikimedia\.org$/ {
	$ganglia_aggregator = "true"

	interface_aggregate { "bond0": orig_interface => "eth0", members => [ "eth0", "eth1" ] }

	include role::cache::bits
}

node "ekrem.wikimedia.org" {
	install_certificate{ "star.wikimedia.org": }
	include standard,
		misc::wapsite,
		misc::apple-dictionary-bridge,
		misc::irc-server,
		misc::mediawiki-irc-relay
}

node "emery.wikimedia.org" {
	$gid=500
	system_role { "misc::log-collector": description => "log collector" }
	sudo_user { "nimishg": privileges => ['ALL = NOPASSWD: ALL'] }
	include standard,
		misc::udp2log::aft,
		misc::udp2log::packetloss,
		misc::udp2log::emery,
		groups::wikidev,
		admins::mortals,
		admins::restricted,
		nrpe,
		misc::udp2log::monitoring,
		misc::udp2log::emeryconfig,
		misc::udp2log::udp-filters
}

node "erzurumi.pmtpa.wmnet" {
	include	standard,
		groups::wikidev,
		accounts::awjrichards,
		accounts::tfinc
}

node /es100[1-4]\.eqiad\.wmnet/ {
	if $hostname == "es1001" {
		include db::es::master
	}
	else {
		include db::es::slave
	}
	if $hostname == "es1004" {
		# replica of ms3 - currently used for backups
		cron { snapshot_mysql: command => "/root/backup.sh", user => root, minute => 15, hour => 4 }
	}
}

node /es[1-4]\.pmtpa\.wmnet/ {
	if $hostname == "es3" {
		include db::es::master
	}
	else {
		include db::es::slave
	}
}

node "dataset1.wikimedia.org" {
	$cluster = "misc"
	$gid=500
	include standard,
		admins::roots,
		misc::download-wikimedia

}

node /^dataset(2|1001)\.wikimedia\.org/ {
	$cluster = "misc"
	$gid=500
	include standard,
		admins::roots,
		groups::wikidev,
		accounts::catrope,
		misc::download-wikimedia,
		misc::download-mirror,
		misc::kiwix-mirror
}

node /^db[1-9]\.pmtpa\.wmnet$/ {
	include db::core
}

node "db10.pmtpa.wmnet" {
	include db::core,
		backup::mysql
}

node /^db1[2-8]\.pmtpa\.wmnet$/ {
	include db::core

	# upgraded hosts
	if $hostname =~ /^db1[2]$/ {
		include mysql::mysqluser,
		mysql::datadirs,
		mysql::conf,
		mysql::packages
	}
}

node /^db2[1-9]\.pmtpa\.wmnet$/ {
	if $hostname == "db21" {
		$ganglia_aggregator = "true"
	}

	include db::core

	# upgraded hosts
	if $hostname =~ /^db2[46]$/ {
		include mysql::mysqluser,
		mysql::datadirs,
		mysql::conf,
		mysql::packages
	}
}

node /^db3[0-9]\.pmtpa\.wmnet$/ {
	if $hostname == "db30" {
		$ganglia_aggregator = "true"
	}

	include db::core

	# upgraded hosts
	if $hostname =~ /^db3(2|6|7|8)$/ {
		include mysql::mysqluser,
		mysql::datadirs,
		mysql::conf,
		mysql::packages
	}
}

node "db40.pmtpa.wmnet" {
	include db::core,
		mysql::packages

	system_role { "lame::not::puppetized": description => "Parser Cache database server" }
}

node /^db4[2]\.pmtpa\.wmnet$/ {
	include db::core,
		mysql::packages
}

node "db41.pmtpa.wmnet" {
	$cluster = "misc"
	$gid=500
	sudo_user { "nimishg": privileges => ['ALL = NOPASSWD: ALL'] }
	include base,
		ganglia,
		ntp::client,
		memcached,
		owa::database,
		groups::wikidev,
		accounts::nimishg
}

# new pmtpa dbs
# New and rebuilt DB's go here as they're rebuilt and moved fully to puppet
# DO NOT add old prod db's to new classes unless you
# know what you're doing!
node "db11.pmtpa.wmnet" {
	include db::core,
		mysql::mysqluser,
		mysql::datadirs,
		mysql::conf,
		mysql::packages
}

node "db19.pmtpa.wmnet" { # dead
	include db::core,
		mysql::mysqluser,
		mysql::datadirs,
		mysql::conf
}

node "db22.pmtpa.wmnet" {
	include db::core,
		mysql::mysqluser,
		mysql::datadirs,
		mysql::conf,
		mysql::packages
}

node /db4[3-9]\.pmtpa\.wmnet/ {
	include db::core,
		mysql::mysqluser,
		mysql::datadirs,
		mysql::conf,
		mysql::packages
}

node /db5[0-9]\.pmtpa\.wmnet/ {
	include db::core,
		mysql::mysqluser,
		mysql::datadirs,
		mysql::conf,
		mysql::packages
}

# eqiad dbs
node /db10[0-9][0-9]\.eqiad\.wmnet/ {
	if $hostname =~ /^db(1001|1017)$/ {
		$ganglia_aggregator = "true"
	}

	include db::core,
		mysql::mysqluser,
		mysql::datadirs,
		mysql::conf,
		mysql::packages
}

node "dobson.wikimedia.org" {
	$ntp_servers = [ "173.9.142.98", "66.250.45.2", "169.229.70.201", "69.31.13.207", "72.167.54.201" ]
	$ntp_peers = [ "linne.wikimedia.org" ]

	$dns_recursor_ipaddress = "208.80.152.131"

	interface_ip { "dns::auth-server": interface => "eth0", address => "208.80.152.130" }
	interface_ip { "dns::recursor": interface => "eth0", address => $dns_recursor_ipaddress }

	include	base,
		ganglia,
		exim::simple-mail-sender,
		ntp::server,
		dns::recursor,
		dns::recursor::monitoring,
		dns::recursor::statistics

	class { "dns::auth-server":
		ipaddress => "208.80.152.130",
		soa_name => "ns0.wikimedia.org",
		master => $dns_auth_master
	}
}

node "fenari.wikimedia.org" {
	$cluster = "misc"
	$domain_search = "wikimedia.org pmtpa.wmnet eqiad.wmnet esams.wikimedia.org"

	$ircecho_infile = "/var/log/logmsg"
	$ircecho_nick = "logmsgbot"
	$ircecho_chans = "#wikimedia-tech"
	$ircecho_server = "irc.freenode.net"

	include standard,
		svn::client,
		nfs::home,
		admins::roots,
		admins::mortals,
		admins::restricted,
		accounts::l10nupdate,
		misc::bastionhost,
		misc::noc-wikimedia,
		misc::extension-distributor,
		misc::scripts,
		misc::ircecho,
		misc::l10nupdate,
		dns::account,
		nrpe,
		drac::management,
		squid::cachemgr,
		accounts::awjrichards,
		mediawiki::packages

	install_certificate{ "star.wikimedia.org": }

	apache_module { php5: name => "php5" }
}

node "formey.wikimedia.org" {
	install_certificate{ "star.wikimedia.org": }

	$sudo_privs = [ 'ALL = NOPASSWD: /usr/local/sbin/add-ldap-user',
			'ALL = NOPASSWD: /usr/local/sbin/delete-ldap-user',
			'ALL = NOPASSWD: /usr/local/sbin/modify-ldap-user',
			'ALL = NOPASSWD: /usr/local/bin/svn-group',
			'ALL = NOPASSWD: /usr/local/sbin/add-labs-user' ]
	sudo_user { [ "demon", "robla", "sumanah", "reedy" ]: privileges => $sudo_privs }

	$cluster = "misc"
	$gid = 550
	$ldapincludes = ['openldap', 'nss', 'utils']
	$ssh_tcp_forwarding = "no"
	$ssh_x11_forwarding = "no"
	include standard,
		svn::server,
		ldap::client::wmf-cluster,
		backup::client,
		gerrit::proxy,
		gerrit::jetty,
		gerrit::ircbot,
		accounts::sumanah
}


node "gallium.wikimedia.org" {
	$cluster = "misc"
	$gid=500
	sudo_user { [ "demon", "hashar", "reedy" ]: privileges => [
		 'ALL = (jenkins) NOPASSWD: ALL'
		,'ALL = NOPASSWD: /etc/init.d/jenkins'
		,'ALL = (testswarm) NOPASSWD: ALL'
		,'ALL = NOPASSWD: /etc/init.d/postgresql-8.4'
		,'ALL = (postgres) NOPASSWD: /usr/bin/psql'
	]}
	include base,
		ganglia,
		ntp::client,
		misc::contint::test,
		misc::contint::test::packages,
		misc::contint::test::jenkins,
		misc::contint::android::sdk,
		misc::contint::test::testswarm,
		admins::roots,
		accounts::demon,
		accounts::hashar,
		accounts::reedy,
		certificates::star_wikimedia_org

	install_certificate{ "star.mediawiki.org": }
}

node "ganglia1001.eqiad.wmnet" {
	include standard,
		ganglia::aggregator
}

node "gilman.wikimedia.org" {

	$exim_signs_dkim = "false"
	$exim_bounce_collector = "false"

	install_certificate{ "star.wikimedia.org": }

	sudo_user { [ "awjrichards", "rfaulk", "nimishg" ]: privileges => ['ALL = NOPASSWD: ALL'] }

	$cluster = "misc"
	$gid = 500
	include	base,
		ntp::client,
		nrpe,
		admins::roots,
		accounts::rfaulk,
		accounts::nimishg,
		accounts::awjrichards,
		misc::jenkins,
		misc::fundraising


}

node /(grosley|aluminium)\.wikimedia\.org/ {

	# variables used in fundraising exim template
	# TODO: properly scope these
	$exim_signs_dkim = "true"
	$exim_bounce_collector = "true"

	install_certificate{ "star.wikimedia.org": }

	sudo_user { [ "awjrichards", "rfaulk", "nimishg", "khorn" ]: privileges => ['ALL = NOPASSWD: ALL'] }

	$cluster = "misc"
	$gid = 500
	include	base,
		ganglia,
		ntp::client,
		nrpe,
		admins::roots,
		accounts::rfaulk,
		accounts::nimishg,
		accounts::zexley,
		accounts::khorn,
		accounts::awjrichards,
		accounts::kaldari,
		accounts::jpostlethwaite,
		accounts::jamesofur,
		accounts::pgehres,
		backup::client,
		misc::fundraising,
		misc::fundraising::mail,
		misc::fundraising::offhost_backups

	if $hostname == "aluminium" {
		include misc::jenkins,
			misc::fundraising::jenkins_maintenance
	}

	cron {
		'offhost_backups':
			user => root,
			minute => '5',
			hour => '0',
			command => '/usr/local/bin/offhost_backups',
			ensure => present,
	}

	monitor_service { "smtp": description => "Exim SMTP", check_command => "check_smtp" }
	monitor_service { "http": description => "HTTP", check_command => "check_http" }
}

node "gurvin.wikimedia.org" {
	include base,
		ganglia,
		ntp::client,
		certificates::wmf_ca
}

node "hooft.esams.wikimedia.org" {
	$ganglia_aggregator = "true"
	$domain_search = "esams.wikimedia.org wikimedia.org esams.wmnet"

	include standard,
		misc::install-server::tftp-server,
		admins::roots,
		admins::mortals,
		admins::restricted,
		ganglia::collector
}

node "marmontel.wikimedia.org" {
	include standard,
		admins::roots,
		svn::client,
		misc::blogs::wikimedia,
		certificates::star_wikimedia_org,
		webserver::apache2::rpaf

		class { "memcached":
			memcached_ip => "127.0.0.1" }

	install_certificate{ "star.wikimedia.org": }

	varnish::instance { "blog":
		name => "",
		vcl => "blog",
		port => 80,
		admin_port => 6082,
		storage => "-s malloc,1G",
		backends => [ 'localhost' ],
		directors => { 'backend' => [ 'localhost' ] },
		backend_options => {
			'port' => 81,
			'connect_timeout' => "5s",
			'first_byte_timeout' => "35s",
			'between_bytes_timeout' => "4s",
			'max_connections' => 100,
			'probe' => "blog",
			'retry5x' => 0
		},
		enable_geoiplookup => "false"
	}
}

node "hooper.wikimedia.org" {
	include standard,
		admins::roots,
		svn::client,
		misc::etherpad,
		misc::blogs::wikimedia,
		certificates::star_wikimedia_org,
		misc::racktables

	install_certificate{ "star.wikimedia.org": }
}

node "hume.wikimedia.org" {
	$cluster = "misc"

	include standard,
		nfs::home,
		misc::scripts,
		misc::maintenance::foundationwiki,
		admins::roots,
		admins::mortals,
		admins::restricted,
		nrpe
}

node "ixia.pmtpa.wmnet" {
	$ganglia_aggregator = "true"
	include db::core
}

node "kaulen.wikimedia.org" {
	system_role { "misc": description => "Bugzilla server" }
	$gid = 500

	include standard,
		admins::roots,
		accounts::demon,
		accounts::hashar,
		accounts::reedy,
		accounts::robla,
		misc::download-mediawiki,
		misc::bugzilla::crons,
		certificates::star_wikimedia_org

	install_certificate{ "star.wikimedia.org": }

	monitor_service { "http": description => "Apache HTTP", check_command => "check_http" }
	sudo_user { [ "demon", "reedy" ]: privileges => ['ALL = (mwdeploy) NOPASSWD: ALL'] }
}

# knsq16-22 are upload squids, 13 and 14 have been decommissioned
 node /knsq(1[6-9]|2[0-2])\.esams\.wikimedia\.org/ {
	$squid_coss_disks = [ 'sdb5', 'sdc', 'sdd' ]
	if $hostname =~ /^knsq1[67]$/ {
		$ganglia_aggregator = "true"
	}

	include role::cache::upload
}

# knsq23-30 are text squids
 node /knsq(2[3-9]|30)\.esams\.wikimedia\.org/ {
	$squid_coss_disks = [ 'sda5', 'sdb5', 'sdc', 'sdd' ]

	include role::cache::text
}

node "linne.wikimedia.org" {
	$ntp_servers = [ "198.186.191.229", "64.113.32.2", "173.8.198.242", "208.75.88.4", "75.144.70.35" ]
	$ntp_peers = [ "dobson.wikimedia.org" ]

	interface_ip { "dns::auth-server": interface => "eth0", address => "208.80.152.142" }
	interface_ip { "misc::url-downloader": interface => "eth0", address => "208.80.152.143" }

	include base,
		ganglia,
		exim::simple-mail-sender,
		ntp::server,
		misc::url-downloader,
		misc::squid-logging::multicast-relay

		class { "dns::auth-server":
			ipaddress => "208.80.152.142",
			soa_name => "ns1.wikimedia.org",
			master => $dns_auth_master
		}
}
# Why would Locke be getting apaches::files for the sudoers... that is just silly...
# removing apaches::files.
node "locke.wikimedia.org" {
	$gid=500
	system_role { "misc::log-collector": description => "log collector" }
	sudo_user { "awjrichards": privileges => ['ALL = NOPASSWD: ALL'] }
	include standard,
		groups::wikidev,
		admins::restricted,
		accounts::awjrichards,
		accounts::datasets,
		misc::udp2log::packetloss,
		misc::udp2log::locke,
		misc::udp2log::lockeconfig,
		misc::udp2log::monitoring,
		nrpe
}

node "lomaria.pmtpa.wmnet" {
	include db::core
}

node /lvs[1-6]\.wikimedia\.org/ {
	$cluster = "misc"

	# PyBal is very dependent on recursive DNS, to the point where it is a SPOF
	# So we'll have every LVS server run their own recursor
	$nameservers = [ $ipaddress, "208.80.152.131", "208.80.152.132" ]
	$dns_recursor_ipaddress = $ipaddress

	if $hostname =~ /^lvs[1256]$/ {
		$lvs_balancer_ips = [ "208.80.152.200", "208.80.152.201", "208.80.152.202", "208.80.152.203", "208.80.152.204", "208.80.152.205", "208.80.152.206", "208.80.152.207", "208.80.152.208", "208.80.152.209", "208.80.152.210", "208.80.152.211", "208.80.152.212", "208.80.152.213", "10.2.1.23", "10.2.1.24", "10.2.1.25" ]
	}
	if $hostname =~ /^lvs[34]$/ {
		$lvs_balancer_ips = [ "10.2.1.1", "10.2.1.11", "10.2.1.12", "10.2.1.13", "10.2.1.21", "10.2.1.22", "10.2.1.27" ]
	}

	include base,
		ganglia,
		dns::recursor,
		lvs::balancer,
		lvs::balancer::runcommand

	$ips = {
		'internal' => {
			'lvs1' => "10.0.0.11",
			'lvs2' => "10.0.0.12",
			'lvs3' => "10.0.0.13",
			'lvs4' => "10.0.0.14",
			'lvs5' => "10.0.0.15",
			'lvs6' => "10.0.0.16",
		},
	}

	# Set up tagged interfaces to all subnets with real servers in them
	interface_tagged { "eth0.2":
		base_interface => "eth0",
		vlan_id => "2",
		address => $ips["internal"][$hostname],
		netmask => "255.255.0.0"
	}

	# Make sure GRO is off
	interface_offload { "eth0 gro": interface => "eth0", setting => "gro", value => "off" }

	# LVS configuration moved to lvs.pp
}

node /lvs100[1-6]\.wikimedia\.org/ {
	$cluster = "misc"

	# PyBal is very dependent on recursive DNS, to the point where it is a SPOF
	# So we'll have every LVS server run their own recursor
	$nameservers = [ $ipaddress, "208.80.152.131", "208.80.152.132" ]
	$dns_recursor_ipaddress = $ipaddress

	if $hostname =~ /^lvs100[14]$/ {
		$lvs_balancer_ips = [ "208.80.154.224", "208.80.154.225", "208.80.154.226", "208.80.154.227", "208.80.154.228", "208.80.154.229", "208.80.154.230", "208.80.154.231", "208.80.154.232", "208.80.154.233", "208.80.154.234", "208.80.154.236", "208.80.154.237", "10.2.2.23", "10.2.2.24", "10.2.2.25", "10.2.2.26" ]
	}

	if $hostname =~ /^lvs100[2356]$/ {
		$lvs_balancer_ips = [ "" ]
	}

	include base,
		ganglia,
		dns::recursor,
		lvs::balancer,
		lvs::balancer::runcommand

	$ips = {
		'public1-a-eqiad' => {
			'lvs1004' => "208.80.154.58",
			'lvs1005' => "208.80.154.59",
			'lvs1006' => "208.80.154.60",
		},
		'public1-b-eqiad' => {
			'lvs1001' => "208.80.154.140",
			'lvs1002' => "208.80.154.141",
			'lvs1003' => "208.80.154.142",
		},
		'private1-a-eqiad' => {
			'lvs1001' => "10.64.1.1",
			'lvs1002' => "10.64.1.2",
			'lvs1003' => "10.64.1.3",
			'lvs1004' => "10.64.1.4",
			'lvs1005' => "10.64.1.5",
			'lvs1006' => "10.64.1.6",
		},
		'private1-b-eqiad' => {
			'lvs1001' => "10.64.17.1",
			'lvs1002' => "10.64.17.2",
			'lvs1003' => "10.64.17.3",
			'lvs1004' => "10.64.17.4",
			'lvs1005' => "10.64.17.5",
			'lvs1006' => "10.64.17.6",
		}
	}

	# Set up tagged interfaces to all subnets with real servers in them
	case $hostname {
		/^lvs100[1-3]$/: {
			# Row A subnets on eth0
			interface_tagged { "eth0.1017":
				base_interface => "eth0",
				vlan_id => "1017",
				address => $ips["private1-a-eqiad"][$hostname],
				netmask => "255.255.252.0"
			}
			# Row B subnets on eth1
			interface_tagged { "eth1.1002":
				base_interface => "eth1",
				vlan_id => "1002",
				address => $ips["public1-b-eqiad"][$hostname],
				netmask => "255.255.255.192"
			}
			interface_tagged { "eth1.1018":
				base_interface => "eth1",
				vlan_id => "1018",
				address => $ips["private1-b-eqiad"][$hostname],
				netmask => "255.255.252.0"
			}
			# Row C subnets on eth2
			# Row D subnets on eth3
		}
		/^lvs100[4-6]$/: {
			# Row B subnets on eth0
			interface_tagged { "eth0.1018":
				base_interface => "eth0",
				vlan_id => "1018",
				address => $ips["private1-b-eqiad"][$hostname],
				netmask => "255.255.252.0"
			}
			# Row A subnets on eth1
			interface_tagged { "eth1.1001":
				base_interface => "eth1",
				vlan_id => "1001",
				address => $ips["public1-a-eqiad"][$hostname],
				netmask => "255.255.255.192"
			}
			interface_tagged { "eth1.1017":
				base_interface => "eth1",
				vlan_id => "1017",
				address => $ips["private1-a-eqiad"][$hostname],
				netmask => "255.255.252.0"
			}
			# Row C subnets on eth2
			# Row D subnets on eth3
		}
	}

	# Make sure GRO is off
	interface_manual { "eth1": interface => "eth1", before => Interface_offload["eth1 gro"] }
	interface_manual { "eth2": interface => "eth2", before => Interface_offload["eth2 gro"] }
	interface_manual { "eth3": interface => "eth3", before => Interface_offload["eth3 gro"] }

	interface_offload { "eth0 gro": interface => "eth0", setting => "gro", value => "off" }
	interface_offload { "eth1 gro": interface => "eth1", setting => "gro", value => "off" }
	interface_offload { "eth2 gro": interface => "eth2", setting => "gro", value => "off" }
	interface_offload { "eth3 gro": interface => "eth3", setting => "gro", value => "off" }
}

node "maerlant.esams.wikimedia.org" {
	include standard
}

node "magnesium.wikimedia.org" {
	include role::swift::eqiad-test
}

node "mchenry.wikimedia.org" {
	$gid = 500
	$ldapincludes = ['openldap']

	$dns_recursor_ipaddress = "208.80.152.132"

	interface_ip { "dns::recursor": interface => "eth0", address => $dns_recursor_ipaddress }

	include base,
		ganglia,
		ntp::client,
		dns::recursor,
		dns::recursor::monitoring,
		dns::recursor::statistics,
		nrpe,
		ldap::client::wmf-corp-cluster,
		backup::client,
		groups::wikidev,
		accounts::jdavis
}

node /mw[1-5]?[0-9]\.pmtpa\.wmnet/ {
	include applicationserver::homeless,
		applicationserver::jobrunner,
		memcached
}

node /mw6[0-1]\.pmtpa\.wmnet/ {
	include applicationserver::bits
}

node /mw(6[2-9]|7[0-4])\.pmtpa\.wmnet/ {
	include applicationserver::api
}

node "lily.knams.wikimedia.org" {
	include ganglia,
		nrpe,
		certificates::star_wikimedia_org

	install_certificate{ "star.wikimedia.org": }
}

node /ms[1-3]\.pmtpa\.wmnet/ {
	$all_drives = [ '/dev/sda', '/dev/sdb', '/dev/sdc', '/dev/sdd', '/dev/sde',
		'/dev/sdf', '/dev/sdg', '/dev/sdh', '/dev/sdi', '/dev/sdj', '/dev/sdk',
		'/dev/sdl', '/dev/sdm', '/dev/sdn', '/dev/sdo', '/dev/sdp', '/dev/sdq',
		'/dev/sdr', '/dev/sds', '/dev/sdt', '/dev/sdu', '/dev/sdv', '/dev/sdw',
		'/dev/sdx', '/dev/sdy', '/dev/sdz', '/dev/sdaa', '/dev/sdab',
		'/dev/sdac', '/dev/sdad', '/dev/sdae', '/dev/sdaf', '/dev/sdag',
		'/dev/sdah', '/dev/sdai', '/dev/sdaj', '/dev/sdak', '/dev/sdal',
		'/dev/sdam', '/dev/sdan', '/dev/sdao', '/dev/sdap', '/dev/sdaq',
		'/dev/sdar', '/dev/sdas', '/dev/sdat', '/dev/sdau', '/dev/sdav' ]

	include role::swift::pmtpa-prod::storage

	interface_aggregate { "bond0": orig_interface => "eth0", members => [ "eth0", "eth1" ] }

	swift::create_filesystem{ $all_drives: partition_nr => "1" }
}

node "ms5.pmtpa.wmnet" {
	include	standard,
		media-storage::thumbs-server,
		media-storage::thumbs-handler
}

node "ms6.esams.wikimedia.org" {
	$thumbs_proxying = "true"
	$thumbs_proxy_source = "http://208.80.152.211"

	interface_aggregate { "bond0": orig_interface => "eth0", members => [ "eth0", "eth1", "eth2", "eth3" ] }

	include standard,
		media-storage::thumbs-server,
		media-storage::htcp-purger
}

node "ms7.pmtpa.wmnet" {
	$cluster = "misc"

	include	base,
		groups::wikidev,
		ntp::client,
		admins::roots,
		admins::restricted,
		misc::zfs::monitoring,
		misc::nfs-server::home::monitoring
}

node "ms8.pmtpa.wmnet" {
	$cluster = "misc"

	include	base,
		ntp::client,
		misc::zfs::monitoring
}

node "ms1002.eqiad.wmnet" {
	include standard,
		misc::images::rsyncd,
		misc::images::rsync
}

node /ms100[4]\.eqiad\.wmnet/ {
	$cluster = "misc"
	$ganglia_aggregator = "true"

	$thumbs_proxying = "true"
	$thumbs_proxy_source = "http://10.0.0.252"

	include standard,
		media-storage::thumbs-server,
		media-storage::htcp-purger
}

node /^ms-fe[1-3]\.pmtpa\.wmnet$/ {
	if $hostname =~ /^ms-fe[12]$/ {
		$ganglia_aggregator = "true"
	}
	$lvs_realserver_ips = [ "10.2.1.27" ]
	include lvs::realserver
	include role::swift::pmtpa-prod::proxy
}
node /^ms-be[1-5]\.pmtpa\.wmnet$/ {
	$all_drives = [ '/dev/sdc', '/dev/sdd', '/dev/sde',
		'/dev/sdf', '/dev/sdg', '/dev/sdh', '/dev/sdi', '/dev/sdj', '/dev/sdk',
		'/dev/sdl' ]

	include role::swift::pmtpa-prod::storage

	swift::create_filesystem{ $all_drives: partition_nr => "1" }
}


node "nickel.wikimedia.org" {
	$ganglia_aggregator = "true"

	include standard,
		ganglia::web,
		certificates::star_wikimedia_org,
		generic::apache::no-default-site

	 install_certificate{ "star.wikimedia.org": }
}

node "nescio.esams.wikimedia.org" {
	$dns_recursor_ipaddress = "91.198.174.6"

	interface_ip { "dns::auth-server": interface => "eth0", address => "91.198.174.4" }
	interface_ip { "dns::recursor": interface => "eth0", address => $dns_recursor_ipaddress }

	include standard,
		dns::recursor,
		dns::recursor::monitoring,
		dns::recursor::statistics

		class { "dns::auth-server":
			ipaddress => "91.198.174.4",
			soa_name => "ns2.wikimedia.org",
			master => $dns_auth_master
		}
}

node /^nfs[12].pmtpa.wmnet/ {

	$ldap_server_bind_ips = ""
	$cluster = "misc"
	$ldapincludes = ['openldap']
	$ldap_certificate = "$hostname.pmtpa.wmnet"
	install_certificate{ "$hostname.pmtpa.wmnet": }

	include standard,
		misc::nfs-server::home,
		misc::nfs-server::home::backup,
		misc::nfs-server::home::rsyncd,
		misc::syslog-server,
		misc::mediawiki-logger,
		ldap::server::wmf-cluster,
		ldap::client::wmf-cluster,
		backup::client

	monitor_service { "$hostname ldap cert": description => "Certificate expiration", check_command => "check_cert!$hostname.pmtpa.wmnet!636!wmf-ca.pem", critical => "true" }
}

node /^owa[1-3]\.wikimedia\.org$/ {
	if $hostname =~ /^owa[12]$/ {
		$ganglia_aggregator = "true"
	}

	include role::swift::pmtpa-prod::proxy
}

node /^payments[1-4]\.wikimedia\.org$/ {
	$cluster = "payments"
	$lvs_realserver_ips = [ "208.80.152.7" ]

	if $hostname =~ /^payments[12]$/ {
		$ganglia_aggregator = "true"
	}

	system_role { "misc::payments": description => "Fundraising payments server" }

	include base::remote-syslog,
		base::sysctl,
		base::resolving,
		base::motd,
		base::monitoring::host,
		lvs::realserver,
		ganglia

	monitor_service { "https": description => "HTTPS", check_command => "check_ssl_cert!payments.wikimedia.org" }
}

node "pdf1.wikimedia.org" {
	$ganglia_aggregator = "true"
	$cluster = "pdf"

	include	standard,
		groups::wikidev,
		accounts::file_mover
}

node "pdf2.wikimedia.org" {
	$ganglia_aggregator = "true"
	$cluster = "pdf"

	include	standard,
		groups::wikidev,
		accounts::file_mover
}

node "pdf3.wikimedia.org" {
	$cluster = "pdf"

	include	standard,
		groups::wikidev,
		accounts::file_mover
}

node "professor.pmtpa.wmnet" {
	$cluster = "misc"
	include base,
		ganglia,
		ntp::client,
		misc::udpprofile::collector,
		misc::graphite
}

node "project1.wikimedia.org" {
	$cluster = "misc"

	include standard
}

node "project2.wikimedia.org" {
	$cluster = "misc"

	include standard,
		groups::wikidev,
		accounts::reedy
}

node "sanger.wikimedia.org" {
	$gid = 500
	$ldapincludes = ['openldap']
	$ldap_certificate = "sanger.wikimedia.org"
	install_certificate{ "sanger.wikimedia.org": }

	include base,
		ganglia,
		ntp::client,
		nrpe,
		ldap::server::wmf-corp-cluster,
		ldap::client::wmf-corp-cluster,
		groups::wikidev,
		accounts::jdavis,
		backup::client

	## hardy doesn't support augeas, so we can't do this. /stab
	#include ldap::server::iptables

	monitor_service { "$hostname ldap cert": description => "Certificate expiration", check_command => "check_cert!$hostname.wikimedia.org!636!wmf-ca.pem", critical => "true" }
}

node /search[12]?[0-9]\.pmtpa\.wmnet/ {
	if $hostname == "search1.pmtpa.wmnet" {
		$ganglia_aggregator = "true"
	}

	include searchserver
}

node "searchidx1.pmtpa.wmnet" {
	$ganglia_aggregator = "true"

	include searchindexer
}

node "searchidx2.pmtpa.wmnet" {
	include searchindexer,
		mediawiki::packages
}

node "singer.wikimedia.org" {
	$cluster = "misc"
	$gid=500
	include standard,
		svn::client,
		certificates::star_wikimedia_org,
		groups::wikidev,
		accounts::austin,
		accounts::awjrichards,
		generic::mysql::client,
		misc::planet


	install_certificate{ "star.wikimedia.org": }
	monitor_service { "secure cert": description => "Certificate expiration", check_command => "check_cert!secure.wikimedia.org!443!Equifax_Secure_CA.pem", critical => "true" }
}

node "sockpuppet.pmtpa.wmnet" {
	include passwords::puppet::database

	include standard,
		backup::client,
		misc::management::ipmi

	class { puppetmaster:
		allow_from => [ "*.wikimedia.org", "*.pmtpa.wmnet", "*.eqiad.wmnet" ],
		config => {
			'dbadapter' => "mysql",
			'dbuser' => "puppet",
			'dbpassword' => $passwords::puppet::database::puppet_production_db_pass,
			'dbserver' => "db9.pmtpa.wmnet"
		}
	}

	class { puppetmaster::dashboard:
		dashboard_environment => "production",
		db_host => "db9.pmtpa.wmnet"
	}
}

node "sodium.wikimedia.org" {

	$nameservers = [ $ipaddress, "208.80.152.131", "208.80.152.132" ]
	$dns_recursor_ipaddress = $ipaddress

	include base,
		ganglia,
		nrpe,
		mailman,
		dns::recursor,
		spamassassin,
		backup::client

	class { exim::roled:
		outbound_ips => [ "208.80.154.4", "2620:0:861:1::2" ],
		local_domains => [ "+system_domains", "+mailman_domains" ],
		enable_mail_relay => "secondary",
		enable_mailman => "true",
		enable_mail_submission => "false",
		enable_spamassassin => "true"
	}

	interface_ip {
		"lists.wikimedia.org_v4": interface => "eth0", address => "208.80.154.4", prefixlen => 32;
		"lists.wikimedia.org_v6": interface => "eth0", address => "2620:0:861:1::2", prefixlen => 128;
	}
}

node "spence.wikimedia.org" {
	$ganglia_aggregator = "true"
	$nagios_server = "true"

	$ircecho_infile = "/var/log/nagios/irc.log"
	$ircecho_nick = "nagios-wm"
	$ircecho_chans = "#wikimedia-operations,#wikimedia-tech"
	$ircecho_server = "irc.freenode.net"

	include standard,
		nagios::monitor,
		nagios::monitor::pager,
		nagios::monitor::jobqueue,
		nagios::ganglia::monitor::enwiki,
		nagios::ganglia::ganglios,
		nagios::nsca::daemon,
		nfs::home,
		admins::roots,
		certificates::wmf_ca,
		backup::client,
		misc::udpprofile::collector,
		misc::ircecho,
		certificates::star_wikimedia_org

	install_certificate{ "star.wikimedia.org": }
}

node /^srv18[789]\.pmtpa\.wmnet$/ {
	include applicationserver::api,
		#applicationserver::jobrunner,
		memcached::disabled
}

node "srv190.pmtpa.wmnet" {
	include applicationserver::homeless,
		applicationserver::jobrunner,
		memcached
}

node /^srv19[12]\.pmtpa\.wmnet$/ {
	$ganglia_aggregator = "true"

	include applicationserver::bits,
		memcached
}

# srv193 is test.wikipedia.org
node "srv193.pmtpa.wmnet" {
	include applicationserver::home,
		memcached
}

# srv194-213 are application servers, memcached
node /^srv(19[4-9]|20[0-9]|21[0-3])\.pmtpa\.wmnet$/ {
	include applicationserver::homeless,
		memcached
}

# srv214-218 are API application servers, memcached
node /^srv21[4-8]\.pmtpa\.wmnet$/ {
	include applicationserver::api,
		memcached
}

# srv219-224 are image scalers
node /^srv(219|22[0-4])\.pmtpa\.wmnet$/ {
	if $hostname == "srv219" {
		$ganglia_aggregator = "true"
	}

	include imagescaler
}

# srv225-230 are applicationservers, memcached
node /^srv(22[5-9]|230)\.pmtpa\.wmnet$/ {
	if $hostname == "srv226" {
		$ganglia_aggregator = "true"
	}

	include applicationserver::homeless,
		memcached
}

# srv231-247 are application servers, jobrunners, memcached
node /^srv(23[1-9]|24[0-7])\.pmtpa\.wmnet$/ {
	include applicationserver::homeless,
		applicationserver::jobrunner,
		memcached
}

node /^srv24[89]\.pmtpa\.wmnet$/ {
	include applicationserver::bits,
		memcached
}

# srv250-257 are API application servers and run memcached
node /^srv25[0-7]\.pmtpa\.wmnet$/ {
	if $hostname =~ /^srv25[45]$/ {
		$ganglia_aggregator = "true"
	}

	include applicationserver::api,
		memcached
}

# srv258 - srv280 are application servers, job runners, memcached
node /^srv(25[89]|2[67][0-9]|280)\.pmtpa\.wmnet$/ {
	if $hostname =~ /^srv25[89]$/ {
		$ganglia_aggregator = "true"
	}

	include applicationserver::homeless,
		applicationserver::jobrunner,
		memcached
}

# FIXME: why is srv281 different?
node "srv281.pmtpa.wmnet" {
	#include applicationserver::homeless,
	#	applicationserver::jobrunner,
	#	 memcached
	include admins::roots,
		admins::mortals,
		apaches::pybal-check,
		imagescaler
}

node /^srv28[2-9]\.pmtpa\.wmnet$/ {
	include applicationserver::homeless,
		applicationserver::jobrunner,
		memcached
}

node "srv290.pmtpa.wmnet" {
	include applicationserver::api,
		memcached
}

node /^srv(29[1-9]|30[01])\.pmtpa\.wmnet$/ {
	include applicationserver::api
}

node /ssl[1-4]\.wikimedia\.org/ {
	if $hostname =~ /^ssl[12]$/ {
		$ganglia_aggregator = "true"
	}

	include protoproxy::ssl
}

node /ssl100[1-4]\.wikimedia\.org/ {
	if $hostname =~ /^ssl100[12]$/ {
		$ganglia_aggregator = "true"
	}

	include protoproxy::ssl
}

node /ssl300[1-4]\.esams\.wikimedia\.org/ {
	if $hostname =~ /^ssl300[12]$/ {
		$ganglia_aggregator = "true"
	}
	if $hostname =~ /^ssl3001$/ {
		include protoproxy::ipv6_labs
		$enable_ipv6_proxy = "true"
	}

	include protoproxy::ssl
}

#sq31-sq36 are api squids
node /sq(3[1-6])\.wikimedia\.org/ {
	$squid_coss_disks = [ 'sda5', 'sdb5', 'sdc', 'sdd' ]
	if $hostname =~ /^sq3[15]$/ {
		$ganglia_aggregator = "true"
	}
	include role::cache::text
}


# sq37-40 are text squids
node /sq(3[7-9]|40)\.wikimedia\.org/ {
	$squid_coss_disks = [ 'sda5', 'sdb5', 'sdc', 'sdd' ]

	include role::cache::text
}

# sq41-50 are old 4 disk upload squids
node /sq(4[1-9]|50)\.wikimedia\.org/ {
	$squid_coss_disks = [ 'sdb5', 'sdc', 'sdd' ]
	if $hostname =~ /^sq4[12]$/ {
		$ganglia_aggregator = "true"
	}

	include role::cache::upload
}

# sq51-58 are new ssd upload squids
node /sq5[0-8]\.wikimedia\.org/ {
	$squid_coss_disks = [ 'sdb5' ]
	include role::cache::upload
}

# sq59-66 are text squids
node /sq(59|6[0-6])\.wikimedia\.org/ {
	$squid_coss_disks = [ 'sda5', 'sdb5' ]
	if $hostname =~ /^sq(59|60)$/ {
		$ganglia_aggregator = "true"
	}

	include role::cache::text
}

# sq67-70 are varnishes for bits.wikimedia.org
node /sq(6[7-9]|70)\.wikimedia\.org/ {
	if $hostname =~ /^sq6[68]$/ {
		$ganglia_aggregator = "true"
	}

	interface_aggregate { "bond0": orig_interface => "eth0", members => [ "eth0", "eth1", "eth2", "eth3" ] }

	include role::cache::bits
}

# sq71-78 are text squids
node /sq7[1-8]\.wikimedia\.org/ {
	$squid_coss_disks = [ 'sda5', 'sdb5' ]

	include role::cache::text
}

# sq79-86 are upload squids
node /sq(79|8[0-6])\.wikimedia\.org/ {
	$squid_coss_disks = [ 'sdb5' ]

	include role::cache::upload
}

node "stafford.pmtpa.wmnet" {
	include standard,
		passwords::puppet::database

	class { puppetmaster:
		allow_from => [ "*.wikimedia.org", "*.pmtpa.wmnet", "*.eqiad.wmnet" ],
		config => {
			'ca' => "false",
			'ca_server' => "sockpuppet.pmtpa.wmnet",
			'dbadapter' => "mysql",
			'dbuser' => "puppet",
			'dbpassword' => $passwords::puppet::database::puppet_production_db_pass,
			'dbserver' => "db9.pmtpa.wmnet",
			'filesdir' => "/var/lib/git/operations/puppet/files",
			'privatefilesdir' => "/var/lib/git/operations/private/files",
			'manifestdir' => "/var/lib/git/operations/puppet/manifests",
			'templatedir' => "/var/lib/git/operations/puppet/templates",
			'softwaredir' => "/var/lib/git/operations/software"
		}
	}
}

node "stat1.wikimedia.org" {
	include standard,
		admins::roots,
		accounts::ezachte,
		accounts::reedy,
		accounts::diederik,
		accounts::aotto
}

node "storage1.wikimedia.org" {

	include standard
}

node "storage2.wikimedia.org" {
	include standard
}

node "storage3.pmtpa.wmnet" {

	$db_cluster = "fundraisingdb"

	include db::core,
		role::db::fundraising::slave,
		role::db::fundraising::dump,
		mysql::packages,
		mysql::mysqluser,
		mysql::datadirs,
		mysql::conf,
		svn::client,
		groups::wikidev,
		accounts::nimishg,
		accounts::rfaulk,
		accounts::awjrichards,
		accounts::khorn,
		accounts::logmover,
		misc::fundraising::impressionlog::compress,
		misc::fundraising::offhost_backups

	cron {
		'offhost_backups':
			user => root,
			minute => '35',
			hour => '1',
			command => '/usr/local/bin/offhost_backups',
			ensure => present,
	}

}

node "streber.wikimedia.org" {
	system_role { "misc": description => "network monitoring server" }

	include base,
		ganglia,
		ganglia::collector,
		ntp::client,
		admins::roots,
		misc::torrus,
		exim::rt,
		misc::rt::server,
		certificates::star_wikimedia_org


	install_certificate{ "star.wikimedia.org": }
	monitor_service { "lighttpd http": description => "Lighttpd HTTP", check_command => "check_http" }
}

node /^snapshot([1-4]\.pmtpa|100[1-4]\.eqiad)\.wmnet/ {
	$gid=500
	include base,
		ntp::client,
		ganglia,
		mediawiki::sync,
		snapshots::packages,
		snapshots::sync,
		snapshots::files,
		snapshots::noapache,
		admins::roots,
		admins::mortals,
		accounts::datasets,
		nfs::data,
		groups::wikidev
}

node "tarin.wikimedia.org" {
	include standard,
	nrpe

	monitor_service { "poolcounterd": description => "poolcounter", check_command => "nrpe_check_poolcounterd" }
}

node "thistle.pmtpa.wmnet" {
	$ganglia_aggregator = "true"
	include db::core
}

node "transcode1.wikimedia.org" {
	include standard,
		misc::dc-cam-transcoder
}

node "tridge.wikimedia.org" {
	include base,
		backup::server
}

node "virt0.wikimedia.org" {
	$cluster = "virt"

	$is_puppet_master = "true"
	$is_labs_puppet_master = "true"
	$ldap_server_bind_ips = "127.0.0.1 $ipaddress_eth0"
	$ldap_certificate = "star.wikimedia.org"
	$dns_auth_ipaddress = "208.80.153.135"
	$dns_auth_soa_name = "labsconsole.wikimedia.org"

	install_certificate{ "star.wikimedia.org": }

	include standard,
		dns::auth-server-ldap,
		openstack::controller
}

node /virt[1-4].pmtpa.wmnet/ {
	$cluster = "virt"
	if $hostname =~ /^virt[23]$/ {
		$ganglia_aggregator = "true"
	}

	include standard,
		openstack::compute
}

node "williams.wikimedia.org" {
	include base,
		ganglia,
		ntp::client,
		certificates::star_wikimedia_org

	install_certificate{ "star.wikimedia.org": }
}

node  "yongle.wikimedia.org" {
	$gid=500
	include	standard,
		groups::wikidev,
		accounts::catrope
}

node "yvon.wikimedia.org" {
	include base,
		ganglia,
		ntp::client,
		certificates::wmf_ca
}

node default {
	include	standard
}
