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
import "geoip.pp"
import "gerrit.pp"
import "imagescaler.pp"
import "iptables.pp"
import "ldap.pp"
import "lvs.pp"
import "mail.pp"
import "media-storage.pp"
import "mediawiki.pp"
import "memcached.pp"
import "misc/*.pp"
import "mobile.pp"
import "mysql.pp"
import "nagios.pp"
import "network.pp"
import "nfs.pp"
import "nrpe.pp"
import "openstack.pp"
import "poolcounter.pp"
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
import "zuul.pp"
import "wikidata.pp"

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

class newstandard {
	include base,
		ganglia,
		ntp::client
}

#############################
# Role classes
#############################

# TODO: Perhaps rename these classes to "role::<class>" to distinguish them
# from classes inside service manifests
# Update: migration is now in progress, into role/<class>.pp. Classes still here
# are old, and probably need to be rewritten.


# TODO: rewrite this old mess.
class applicationserver_old {
	class parent {
		$cluster = "appserver"
		$nagios_group = "${cluster}_${::site}"
	}

	# applicationserver::labs bootstrap a MediaWiki Apache for 'beta'
	class labs inherits parent {
		include standard,
			nfs::upload::labs,
			mediawiki::packages,
			apaches::cron,
			apaches::service,
			apaches::monitoring::labs,
			geoip
	}

	class jobrunner {
		class {"mediawiki_new::jobrunner": }
	}

}

class protoproxy::ssl {
	$cluster = "ssl"

	$enable_ipv6_proxy = true

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

node /^amslvs[1-4]\.esams\.wikimedia\.org$/ {
	$cluster = "lvs"

	if $hostname =~ /^amslvs[12]$/ {
		$ganglia_aggregator = "true"
	}

	# Older PyBal is very dependent on recursive DNS, to the point where it is a SPOF
	# So we'll have every LVS server run their own recursor
	$nameservers_prefix = [ $ipaddress ]
	include dns::recursor

	include lvs::configuration
	$sip = $lvs::configuration::lvs_service_ips[$::realm]

	$lvs_balancer_ips = $::hostname ? {
		/^amslvs[13]$/ => [
			$sip['text'][$::site],
			$sip['bits'][$::site],
			$sip['ipv6'][$::site],
			],
		/^amslvs[24]$/ => [
			$sip['upload'][$::site],
			$sip['ipv6'][$::site],
			]
	}

	interface_add_ip6_mapped { "main": interface => "eth0" }

	include base,
		ganglia

	class { "lvs::balancer": service_ips => $lvs_balancer_ips }

	# Make sure GRO is off
	interface_offload { "eth0 gro": interface => "eth0", setting => "gro", value => "off" }
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

# analytics1001.wikimedia.org is the analytics cluster master.
node "analytics1001.wikimedia.org" {
	include role::analytics
	# analytics1001 will get event.gif UDP stream traffic.
	# include udp2log iptables rules.
	include misc::udp2log::iptables
}

# analytics1027 hosts the frontend
# interfaces to Kraken and Hadoop.
node "analytics1027.eqiad.wmnet" {
	include role::analytics::frontend
}

# analytics1002 - analytics1026
node /analytics10(0[2-9]|1[0-9]|2[0-6])\.eqiad\.wmnet/ {
	# ganglia aggregator for the Analytics cluster.
	if ($hostname == "analytics1003" or $hostname == "analytics1011") {
		$ganglia_aggregator = "true"
	}

	include role::analytics
}




node "argon.wikimedia.org" {
	$cluster = "misc"
	include base,
		ganglia,
		ntp::client,
		misc::limesurvey

	install_certificate{ "star.wikimedia.org": }
	monitor_service { "survey cert": description => "Certificate expiration", check_command => "check_cert!survey.wikimedia.org!443!Equifax_Secure_CA.pem", critical => "true" }
}

node /(arsenic|niobium|strontium|palladium)\.(wikimedia\.org|eqiad\.wmnet)/ {
	if $hostname =~ /^(arsenic|niobium)$/ {
		$ganglia_aggregator = "true"
	}

	interface_aggregate { "bond0": orig_interface => "eth0", members => [ "eth0", "eth1", "eth2", "eth3" ] }

	interface_add_ip6_mapped { "main":
		require => Interface_aggregate[bond0],
		interface => "bond0"
	}

	include role::cache::bits
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
		misc::deployment::scripts,
		nrpe,
		nfs::netapp::home::othersite
}

node "bellin.pmtpa.wmnet"{
	include role::db::core,
		mysql::mysqluser,
		mysql::datadirs,
		mysql::conf,
		mysql::packages
}

node "beryllium.wikimedia.org" {
	include newstandard
}

node "blondel.pmtpa.wmnet" {
	include role::db::core,
		mysql::mysqluser,
		mysql::datadirs,
		mysql::conf,
		mysql::packages
}

node "boron.wikimedia.org" {
	include newstandard
}

node "brewster.wikimedia.org" {

	$tftpboot_server_type = 'master'

	include standard,
		misc::install-server,
		backup::client
}

node  "cadmium.eqiad.wmnet" {
	include	standard
}

node "calcium.wikimedia.org" {
	$cluster = "misc"

	include standard,
		misc::smokeping
}

node /^(capella|nitrogen)\.wikimedia\.org$/ {

	include standard,
		role::ipv6relay

	if versioncmp($::lsbdistrelease, "12.04") >= 0 {
		interface_add_ip6_mapped { "main": interface => "eth0" }
	}

}
node "carbon.wikimedia.org" {
	$cluster = "misc"
	$ganglia_aggregator = "true"

	include standard,
		backup::client,
		misc::install-server::tftp-server
}

node /^(chromium|hydrogen)\.wikimedia\.org$/ {
	include standard,
			role::dns::recursor

	interface_add_ip6_mapped { "main": interface => "eth0" }
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

node /^cp10(2[1-9]|3[0-6])\.eqiad\.wmnet$/ {
	if $hostname =~ /^cp102[12]$/ {
		$ganglia_aggregator = "true"
	}

	interface_add_ip6_mapped { "main": interface => "eth0" }

	include role::cache::upload
}

# eqiad varnish for m.wikipedia.org
node /^cp104[1-4]\.(wikimedia\.org|eqiad\.wmnet)$/ {

	if $hostname =~ /^cp104(3|4)$/ {
		$ganglia_aggregator = "true"
	}

	interface_add_ip6_mapped { "main": }

	include role::cache::mobile
}

node /^cp300[12]\.esams\.wikimedia\.org$/ {
	interface_aggregate { "bond0": orig_interface => "eth0", members => [ "eth0", "eth1" ] }

	interface_add_ip6_mapped { "main":
		require => Interface_aggregate[bond0],
		interface => "bond0"
	}
}

node /^cp300[34]\.esams\.wikimedia\.org$/ {
	if $::hostname =~ /^cp300[34]$/ {
		$ganglia_aggregator = "true"
	}

	interface_add_ip6_mapped { "main": }

	include role::cache::upload
}

node /^cp(3019|302[0-2])\.esams\.wikimedia\.org$/ {
	if $::hostname =~ /^cp(3019|3020)$/ {
		$ganglia_aggregator = "true"
	}

	interface_add_ip6_mapped { "main": }

	include role::cache::bits
}


node "dataset2.wikimedia.org" {
	$cluster = "misc"
	$gid=500
	include standard,
		admins::roots,
		groups::wikidev,
		accounts::catrope,
		misc::download-wikimedia,
		misc::download-primary,
		misc::kiwix-mirror
}

node "dataset1001.wikimedia.org" {
	$cluster = "misc"
	$gid=500
	interface_aggregate { "bond0": orig_interface => "eth0", members => [ "eth0", "eth1" ] }
	include standard,
		admins::roots,
		groups::wikidev,
		accounts::catrope,
		misc::download-wikimedia,
		misc::download-mirror,
		generic::gluster
		mount { "/mnt/glusterpublicdata":
		      device => "labstore1.pmtpa.wmnet:/publicdata-project",
		      fstype => "glusterfs",
		      options => "defaults,_netdev=bond0,log-level=WARNING,log-file=/var/log/gluster.log",
		      require => Package["glusterfs"],
		      ensure => mounted;
		}

}

node /^db(9|10)\.pmtpa\.wmnet$/ {
  ## do not have most of our current puppet classe
  include role::db::core
}

node /^db3[123467]\.pmtpa\.wmnet$/ {
    include mysql::mysqluser,
    mysql::datadirs,
    mysql::conf,
    mysql::packages,
    role::db::core
}

node /^db4[12]\.pmtpa\.wmnet$/ {
## currently dead
}

node /db4[4-9]\.pmtpa\.wmnet/ {
	include role::db::core,
		mysql::mysqluser,
		mysql::datadirs,
		mysql::conf,
		mysql::packages
}

node /db5[0345679]\.pmtpa\.wmnet/ {
	if $hostname =~ /^db(50|51)$/ {
		$ganglia_aggregator = "true"
	}

	if $hostname == "db59" {
		$mariadb = true
	}

	include role::db::core,
		mysql::mysqluser,
		mysql::datadirs,
		mysql::conf,
		mysql::packages
}

node /db6[0]\.pmtpa\.wmnet/ {
	include role::db::core,
		mysql::mysqluser,
		mysql::datadirs,
		mysql::conf,
		mysql::packages
}

node /db6[12]\.pmtpa\.wmnet/ {
##test boxes
}

node /db6([3-9])\.pmtpa\.wmnet/ {
	include role::db::core,
		mysql::mysqluser,
		mysql::datadirs,
		mysql::conf,
		mysql::packages
}

node "db78.pmtpa.wmnet" {
	include role::fundraising::database::dump_slave
	class { 'misc::fundraising::backup::archive_sync': hour => [4,12,20], minute => 5 }
}

# pmtpa dbs (coredb module)
node /db(38)\.pmtpa\.wmnet/ {
  include role::coredb::s1
}

node /db(52)\.pmtpa\.wmnet/ {
  include role::coredb::s2
}

node /db(39)\.pmtpa\.wmnet/ {
  include role::coredb::s3
}

node /db(51)\.pmtpa\.wmnet/ {
  if $hostname =~ /^db51/ {
    $ganglia_aggregator = "true"
  }
  include role::coredb::s4
}

node /db(35)\.pmtpa\.wmnet/ {
  include role::coredb::s5
}

node /db(43)\.pmtpa\.wmnet/ {
  include role::coredb::s6
}

node /db(58)\.pmtpa\.wmnet/ {
  include role::coredb::s7
}

# eqiad dbs
node /db10(01|17|42|43|49|50)\.eqiad\.wmnet/ {
	if $hostname =~ /^db10(01|17)/ {
		$ganglia_aggregator = "true"
	}

	if $hostname == "db1043" {
		class { role::coredb::s1 : mariadb => true }
	} else {
		include role::coredb::s1
	}
}

node /db10(02|09|18|34)\.eqiad\.wmnet/ {
	include role::coredb::s2
}

node /db10(03|10|19|35)\.eqiad\.wmnet/ {
	include role::coredb::s3
}

node /db10(04|11|20|38)\.eqiad\.wmnet/ {
	include role::coredb::s4
}

node /db10(05|21|26|39)\.eqiad\.wmnet/ {
	if $hostname =~ /^db1021/ {
		$ganglia_aggregator = "true"
	}

	include role::coredb::s5
}

node /db10(06|22|27|40)\.eqiad\.wmnet/ {
	include role::coredb::s6
}

node /db10(07|24|28|41)\.eqiad\.wmnet/ {
	include role::coredb::s7
}

## m2 shard
node /db104[68]\.eqiad\.wmnet/ {
	include role::coredb::m2
}

## eqiad fundraising DBs
node /db10(08|13|25)\.eqiad\.wmnet/ {
	include mysql::mysqluser,
		mysql::datadirs,
		mysql::packages,
		mysql::conf

	  if $hostname == "db1008" {
		include role::fundraising::database::master
	  }
	  if $hostname == "db1013" {
		include role::fundraising::database::slave
	  }
	  if $hostname == "db1025" {
		include role::fundraising::database::dump_slave
	  }
}

## researchdb (currently lucid)
node /db1047\.eqiad\.wmnet/ {
	include mysql::mysqluser,
		mysql::datadirs,
		role::db::core
}

## not currently in production and/or hardware issues
node /db10(1[2456]|2[39]|3[012367]|4[45])\.eqiad\.wmnet/ {
	  include role::db::core,
		mysql::mysqluser,
		mysql::datadirs,
		mysql::conf,
		mysql::packages
}

node "dobson.wikimedia.org" {
	interface_ip { "dns::auth-server": interface => "eth0", address => "208.80.152.130" }
	interface_ip { "dns::recursor": interface => "eth0", address => "208.80.152.131" }

	include	base,
		ganglia,
		exim::simple-mail-sender,
		dns::recursor::statistics

	include network::constants

	class { 'ntp::server':
		servers => [ "173.9.142.98", "66.250.45.2", "169.229.70.201", "69.31.13.207", "72.167.54.201" ],
		peers => [ "linne.wikimedia.org" ],
	}

	class { "dns::recursor":
		listen_addresses => [ "208.80.152.131" ],
		allow_from => $network::constants::all_networks
	}
	dns::recursor::monitor { "208.80.152.131": }

	class { "dns::auth-server":
		ipaddress => "208.80.152.130",
		soa_name => "ns0.wikimedia.org",
		master => $dns_auth_master
	}
}

node "ekrem.wikimedia.org" {
	include standard,
		search::apple-dictionary-bridge,
		misc::irc-server,
		misc::mediawiki-irc-relay
}

# base_analytics_logging_node is defined in role/logging.pp
node "emery.wikimedia.org" inherits "base_analytics_logging_node" {
	include
		admins::mortals,
		generic::sysctl::high-bandwidth-rsync,
		misc::udp2log::utilities,
		misc::udp2log

	sudo_user { "otto": privileges => ['ALL = NOPASSWD: ALL'] }

	# emery's udp2log instance
	# saves logs mainly in /var/log/squid.
	# TODO: Move this to /var/log/udp2log
	misc::udp2log::instance { "emery": log_directory => "/var/log/squid" }

	# Set up an rsync daemon module for udp2log logrotated
	# archives.  This allows stat1 to copy logs from the
	# logrotated archive directory
	class { "misc::udp2log::rsyncd":
		path    => "/var/log/squid",
		require => Misc::Udp2log::Instance["emery"],
	}

	# aft (Article Feedback Tool)
	# udp2log instance for clicktracking logs.
	misc::udp2log::instance { "aft":
		log_directory       => "/var/log/squid/aft",
		port                => "8421",
		# packet-loss.log is not generated for clicktracking logs,
		# so packet loss monitoring is disabled.
		monitor_packet_loss => false,
	}
}

node /(ersch|tarin)\.pmtpa\.wmnet/ {
	include standard,
		role::poolcounter
}

node "erzurumi.pmtpa.wmnet" {
	include	role::fundraising::messaging
}

node "loudon.wikimedia.org" {
	include	role::fundraising::logger
}

node "grosley.wikimedia.org" {
	include role::fundraising::civicrm
	class { 'misc::fundraising::backup::archive_sync': hour => 0, minute => 5 }
}

node "aluminium.wikimedia.org" {
	include role::fundraising::civicrm,
		misc::fundraising::jenkins
	class { 'misc::fundraising::backup::archive_sync': hour => [0,8,16], minute => 5 }
}


# es1 equad
node /es100[1-4]\.eqiad\.wmnet/ {
	if $hostname == "es1001" {
		class { "role::db::es": mysql_role => "master" }
	}
	else {
		include role::db::es
	}
}

node /es[1-4]\.pmtpa\.wmnet/ {
	if $hostname == "es1" {
		class { "role::db::es": mysql_role => "master" }
	}
	else {
		include role::db::es
	}
}

# es2-3
node /es([5-9]|10)\.pmtpa\.wmnet/ {
	include role::db::core,
		mysql::mysqluser,
		mysql::datadirs,
		mysql::conf,
		mysql::packages
}

node /es100[5-7]\.eqiad\.wmnet/ {
	include role::coredb::es2
}

node /es10(0[89]|10)\.eqiad\.wmnet/ {
	include role::coredb::es3
}

node "fenari.wikimedia.org" {
	$cluster = "misc"
	$domain_search = "wikimedia.org pmtpa.wmnet eqiad.wmnet esams.wikimedia.org"

	$ircecho_infile = "/var/log/logmsg"
	$ircecho_nick = "logmsgbot"
	$ircecho_chans = "#wikimedia-operations"
	$ircecho_server = "irc.freenode.net"

	include standard,
		svn::client,
		nfs::netapp::home,
		admins::roots,
		admins::mortals,
		admins::restricted,
		misc::bastionhost,
		misc::deployment,
		misc::noc-wikimedia,
		mediawiki::former-extdist-removesoon,
		misc::deployment::scap_scripts,
		misc::ircecho,
		misc::deployment::l10nupdate,
		dns::account,
		nrpe,
		drac::management,
		squid::cachemgr,
		accounts::awjrichards,
		accounts::erosen,
		mediawiki_new,
		generic::wikidev-umask

	install_certificate{ "star.wikimedia.org": }
}

node "fluorine.eqiad.wmnet" {
	$cluster = "misc"

	include standard,
		admins::roots,
		admins::mortals,
		admins::restricted,
		nrpe

	class { "role::logging::mediawiki":
		monitor => false,
		log_directory => "/a/mw-log"
	}

}

node "formey.wikimedia.org" {
	install_certificate{ "star.wikimedia.org": }

	$sudo_privs = [ 'ALL = NOPASSWD: /usr/local/sbin/add-ldap-user',
			'ALL = NOPASSWD: /usr/local/sbin/delete-ldap-user',
			'ALL = NOPASSWD: /usr/local/sbin/modify-ldap-user',
			'ALL = NOPASSWD: /usr/local/bin/svn-group',
			'ALL = NOPASSWD: /usr/local/sbin/add-labs-user',
			'ALL = NOPASSWD: /var/lib/gerrit2/review_site/bin/gerrit.sh' ]
	sudo_user { [ "robla", "sumanah", "reedy" ]: privileges => $sudo_privs }

	# full root for gerrit admin (RT-3698)
	sudo_user { "demon": privileges => ['ALL = NOPASSWD: ALL'] }

	$gid = 550
	$ldapincludes = ['openldap', 'nss', 'utils']
	$ssh_tcp_forwarding = "no"
	$ssh_x11_forwarding = "no"
	include role::gerrit::production::slave,
		svn::server,
		backup::client

	class { "role::ldap::client::labs": ldapincludes => $ldapincludes }
}


node "gallium.wikimedia.org" {
	$cluster = "misc"
	$gid=500
	sudo_user { [ "demon", "krinkle", "reedy", "dsc" ]: privileges => [
		 'ALL = (jenkins) NOPASSWD: ALL'
		,'ALL = NOPASSWD: /etc/init.d/jenkins'
		,'ALL = (testswarm) NOPASSWD: ALL'
		,'ALL = NOPASSWD: /etc/init.d/postgresql-8.4'
		,'ALL = (postgres) NOPASSWD: /usr/bin/psql'
	]}

	# full root for Jenkins admin (RT-4101)
	sudo_user { "hashar": privileges => ['ALL = NOPASSWD: ALL'] }

	include standard,
		misc::contint::test,
		misc::contint::test::packages,
		misc::contint::analytics::packages,
		misc::contint::test::jenkins,
		misc::contint::android::sdk,
		misc::contint::test::testswarm,
		misc::docsite,
		misc::docs::puppet,
		role::zuul::production,
		admins::roots,
		admins::jenkins

	install_certificate{ "star.mediawiki.org": }
	install_certificate{ "star.wikimedia.org": }
}

node "gurvin.wikimedia.org" {
	include base,
		ganglia,
		ntp::client,
		certificates::wmf_ca
}


node "helium.eqiad.wmnet" {
	include standard,
		role::poolcounter
}

node "hooft.esams.wikimedia.org" {
	$ganglia_aggregator = "true"
	$domain_search = "esams.wikimedia.org wikimedia.org esams.wmnet"

	include standard,
		misc::install-server::tftp-server,
		admins::roots,
		admins::mortals,
		admins::restricted
}

# base_analytics_logging_node is defined in role/logging.pp
node "locke.wikimedia.org" inherits "base_analytics_logging_node" {
	include
		accounts::dsc,
		accounts::datasets,
		misc::udp2log::utilities,
		misc::udp2log

	sudo_user { "otto": privileges => ['ALL = NOPASSWD: ALL'] }

	# locke's udp2log instance stores logs
	# mainly in /a/squid.
	# TODO: Move log_directory to /var/log/udp2log
	misc::udp2log::instance { "locke": log_directory => "/a/squid" }

	# mount netapp to inject to fundraising banner log pipeline
    class { "nfs::netapp::fr_archive": mountpoint => "/a/squid/fundraising/logs/fr_archive" }

	# Set up an rsync daemon module for udp2log logrotated
	# archives.  This allows stat1 to copy logs from the
	# logrotated archive directory
	class { "misc::udp2log::rsyncd":
		path    => "/a/squid",
		require => Misc::Udp2log::Instance["locke"],
	}
}

node "manutius.wikimedia.org" {
	$corerouters = [
		"cr1-sdtpa.wikimedia.org",
		"cr2-pmtpa.wikimedia.org",
		"csw1-esams.wikimedia.org",
		"csw1-sdtpa.wikimedia.org",
		"cr1-esams.wikimedia.org",
		"cr2-knams.wikimedia.org",
		"csw2-esams.wikimedia.org",
		"cr1-eqiad.wikimedia.org",
		"cr2-eqiad.wikimedia.org",
		"mr1-pmtpa.mgmt.pmtpa.wmnet",
		"pfw1-eqiad.wikimedia.org"
	]

	$accessswitches = [
		"asw-a4-sdtpa.mgmt.pmtpa.wmnet",
		"asw-a5-sdtpa.mgmt.pmtpa.wmnet",
		"asw-b-sdtpa.mgmt.pmtpa.wmnet",
		"asw-d-pmtpa.mgmt.pmtpa.wmnet",
		"asw-d1-sdtpa.mgmt.pmtpa.wmnet",
		"asw-d2-sdtpa.mgmt.pmtpa.wmnet",
		"asw-d3-sdtpa.mgmt.pmtpa.wmnet",
		"asw2-d3-sdtpa.mgmt.pmtpa.wmnet",
		"asw-a-eqiad.mgmt.eqiad.wmnet",
		"asw-b-eqiad.mgmt.eqiad.wmnet",
		"asw-c-eqiad.mgmt.eqiad.wmnet",
		"asw2-a5-eqiad.mgmt.eqiad.wmnet",
		"psw1-eqiad.mgmt.eqiad.wmnet",
		"msw1-eqiad.mgmt.eqiad.wmnet",
		"msw2-pmtpa.mgmt.pmtpa.wmnet",
		"msw2-sdtpa.mgmt.pmtpa.wmnet"
	]

	$storagehosts = [ "nas1-a.pmtpa.wmnet", "nas1-b.pmtpa.wmnet", "nas1001-a.eqiad.wmnet", "nas1001-b.eqiad.wmnet" ]

	include standard,
		webserver::apache,
		misc::torrus,
		misc::torrus::web,
		misc::torrus::xml-generation::cdn,
		ganglia::collector

	include passwords::network
	$snmp_ro_community = $passwords::network::snmp_ro_community

	misc::torrus::discovery::ddxfile {
		"corerouters":
			subtree => "/Core_routers",
			snmp_community => $snmp_ro_community,
			hosts => $corerouters;
		"accessswitches":
			subtree => "/Access_switches",
			snmp_community => $snmp_ro_community,
			hosts => $accessswitches;
		"storage":
			subtree => "/Storage",
			snmp_community => $snmp_ro_community,
			hosts => $storagehosts
	}
}

node "hooper.wikimedia.org" {
	include standard,
		admins::roots,
		svn::client,
		misc::etherpad,
		misc::racktables

	install_certificate{ "star.wikimedia.org": }
}

node "hume.wikimedia.org" {
	$cluster = "misc"

	include standard,
		nfs::netapp::home,
		misc::deployment::scap_scripts,
		misc::maintenance::foundationwiki,
		misc::maintenance::pagetriage,
		misc::maintenance::refreshlinks,
		misc::maintenance::translationnotifications,
		misc::maintenance::wikidata,
		misc::maintenance::tor_exit_node,
		misc::maintenance::echo_mail_batch,
		misc::maintenance::update_flaggedrev_stats,
		misc::maintenance::update_special_pages,
		misc::maintenance::parsercachepurging,
		misc::maintenance::geodata,
		admins::roots,
		admins::mortals,
		admins::restricted,
		nrpe

}

node "iron.wikimedia.org" {
	$cluster = "misc"

	include standard,
	admins::roots,
	misc::management::ipmi

	# search QA scripts for ops use
	include search::searchqa

	# let's see if the swiftcleaner can run here
	include swift::cleaner

	# include the swift cli so I can call out to swift instances
	include swift::utilities
}

node "ixia.pmtpa.wmnet" {
	$ganglia_aggregator = "true"
	include role::db::core
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
		misc::bugzilla::server,
		misc::bugzilla::crons,
		misc::bugzilla::communitymetrics,
		misc::bugzilla::report

	install_certificate{ "star.wikimedia.org": }

	monitor_service { "memorysurge": description => "Memory using more than expected", check_command => "check_memory_used!500000!510000" }
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

node /labstore[1-4]\.pmtpa\.wmnet/ {

	$cluster = "gluster"
	$ldapincludes = ['openldap', 'nss', 'utils']

	if $hostname =~ /^labstore[12]$/ {
		$ganglia_aggregator = "true"
	}

	include standard,
		openstack::project-storage

	class { "role::ldap::client::labs": ldapincludes => $ldapincludes }

	if $hostname =~ /^labstore2$/ {
		include openstack::project-storage-cron
	}

}

node "linne.wikimedia.org" {
	interface_ip { "dns::auth-server": interface => "eth0", address => "208.80.152.142" }
	interface_ip { "misc::url-downloader": interface => "eth0", address => "208.80.152.143" }

	include base,
		ganglia,
		exim::simple-mail-sender,
		misc::url-downloader
		# misc::squid-logging::multicast-relay # linne has no iptable rules, and this appears unused here

	class { 'ntp::server':
		servers => [ "198.186.191.229", "64.113.32.2", "173.8.198.242", "208.75.88.4", "75.144.70.35" ],
		peers => [ "dobson.wikimedia.org" ],
	}

		class { "dns::auth-server":
			ipaddress => "208.80.152.142",
			soa_name => "ns1.wikimedia.org",
			master => $dns_auth_master
		}
}

node "lomaria.pmtpa.wmnet" {
	include role::db::core
}

node /lvs[1-6]\.wikimedia\.org/ {
	$cluster = "lvs"

	if $hostname =~ /^lvs[12]$/ {
		$ganglia_aggregator = "true"
	}

	# Older PyBal is very dependent on recursive DNS, to the point where it is a SPOF
	# So we'll have every LVS server run their own recursor
	$nameservers_prefix = [ $ipaddress ]
	include dns::recursor

	include lvs::configuration
	$sip = $lvs::configuration::lvs_service_ips[$::realm]

	$lvs_balancer_ips = $::hostname ? {
		/^lvs[15]$/ => [
			$sip['upload'][$::site],
			$sip['ipv6'][$::site],
			$sip['payments'][$::site],
			$sip['dns_auth'][$::site],
			$sip['dns_rec'][$::site],
			$sip['osm'][$::site],
			$sip['misc_web'][$::site],
			],
		/^lvs[26]$/ => [
			$sip['text'][$::site],
			$sip['bits'][$::site],
			$sip['ipv6'][$::site],
			],
		/^lvs[34]$/ => [
			$sip['apaches'][$::site],
			$sip['rendering'][$::site],
			$sip['api'][$::site],
			$sip['search_pool1'][$::site],
			$sip['search_pool2'][$::site],
			$sip['search_pool3'][$::site],
			$sip['search_pool4'][$::site],
			$sip['search_prefix'][$::site],
			$sip['swift'][$::site],
			$sip['parsoid'][$::site]
			]
	}

	include base,
		ganglia,
		lvs::balancer::runcommand

	class { "lvs::balancer": service_ips => $lvs_balancer_ips }

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

	interface_add_ip6_mapped { "main": interface => "eth0" }

	# Set up tagged interfaces to all subnets with real servers in them
	interface_tagged { "eth0.2":
		base_interface => "eth0",
		vlan_id => "2",
		address => $ips["internal"][$hostname],
		netmask => "255.255.0.0"
	}

	# Make sure GRO is off
	interface_offload { "eth0 gro": interface => "eth0", setting => "gro", value => "off" }
}

node /lvs100[1-6]\.wikimedia\.org/ {
	$cluster = "lvs"

	if $hostname =~ /^lvs100[12]$/ {
		$ganglia_aggregator = "true"
	}

	# Older PyBal is very dependent on recursive DNS, to the point where it is a SPOF
	# So we'll have every LVS server run their own recursor
	$nameservers_prefix = [ $ipaddress ]
	include dns::recursor

	include lvs::configuration
	$sip = $lvs::configuration::lvs_service_ips[$::realm]

	$lvs_balancer_ips = $::hostname? {
		/^lvs100[14]$/ => [
			$sip['text'][$::site],
			$sip['bits'][$::site],
			$sip['mobile'][$::site],
			$sip['ipv6'][$::site],
			],
		/^lvs100[25]$/ => [
			$sip['upload'][$::site],
			$sip['ipv6'][$::site],
			$sip['payments'][$::site],
			$sip['dns_auth'][$::site],
			$sip['dns_rec'][$::site],
			$sip['osm'][$::site],
			$sip['misc_web'][$::site],
			],
		/^lvs100[36]$/ => [
			$sip['search_pool1'][$::site],
			$sip['search_pool2'][$::site],
			$sip['search_pool3'][$::site],
			$sip['search_pool4'][$::site],
			$sip['search_prefix'][$::site],
			$sip['swift'][$::site],
			$sip['parsoid'][$::site]
			]
	}

	include base,
		ganglia,
		lvs::balancer::runcommand

	class { "lvs::balancer": service_ips => $lvs_balancer_ips }

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

	interface_add_ip6_mapped { "main": interface => "eth0" }

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

node "manganese.wikimedia.org" {
	install_certificate{ "star.wikimedia.org": }

	$sudo_privs = [ 'ALL = NOPASSWD: /usr/local/sbin/add-ldap-user',
			'ALL = NOPASSWD: /usr/local/sbin/delete-ldap-user',
			'ALL = NOPASSWD: /usr/local/sbin/modify-ldap-user',
			'ALL = NOPASSWD: /usr/local/bin/svn-group',
			'ALL = NOPASSWD: /usr/local/sbin/add-labs-user',
			'ALL = NOPASSWD: /var/lib/gerrit2/review_site/bin/gerrit.sh' ]
	sudo_user { [ "robla", "reedy" ]: privileges => $sudo_privs }

	# full root for gerrit admin (RT-3698)
	sudo_user { "demon": privileges => ['ALL = NOPASSWD: ALL'] }

	$ldapincludes = ['openldap', 'nss', 'utils']
	$ssh_tcp_forwarding = "no"
	$ssh_x11_forwarding = "no"
	# Note: whenever moving Gerrit out of manganese, you will need
	# to update the role::zuul::production
	include role::gerrit::production,
		backup::client

	class { "role::ldap::client::labs": ldapincludes => $ldapincludes }
}

node "marmontel.wikimedia.org" {
	include standard,
		admins::roots,
		svn::client,
		misc::blogs::wikimedia
}

node /mc(1[0-9]|[0-9])\.pmtpa\.wmnet/ {
	$cluster = "memcached"
	if $hostname =~ /^mc[12]$/ {
		$ganglia_aggregator = "true"
	}

	# replication mappings may end up all over the place
	# once servers die and are replaced, so making this
	# explicit for now.
	$redis_replication = {
		'site' => false,
		'mc1' => 'mc1001',
		'mc2' => 'mc1002',
		'mc3' => 'mc1003',
		'mc4' => 'mc1004',
		'mc5' => 'mc1005',
		'mc6' => 'mc1006',
		'mc7' => 'mc1007',
		'mc8' => 'mc1008',
		'mc9' => 'mc1009',
		'mc10' => 'mc1010',
		'mc11' => 'mc1011',
		'mc12' => 'mc1012',
		'mc13' => 'mc1013',
		'mc14' => 'mc1014',
		'mc15' => 'mc1015',
		'mc16' => 'mc1016',
	}
	include role::memcached

	file { "/a":
		ensure => directory;
	}

	class { "redis":
		maxmemory         => "500Mb",
		redis_replication => $redis_replication,
	}
	include redis::ganglia
}

node /mc(10[01][0-9])\.eqiad\.wmnet/ {
	$cluster = "memcached"
	if $hostname =~ /^mc100[12]$/ {
		$ganglia_aggregator = "true"
	}

	$redis_replication = {
		'site' => 'pmtpa.wmnet',
		'mc1001' => 'mc1',
		'mc1002' => 'mc2',
		'mc1003' => 'mc3',
		'mc1004' => 'mc4',
		'mc1005' => 'mc5',
		'mc1006' => 'mc6',
		'mc1007' => 'mc7',
		'mc1008' => 'mc8',
		'mc1009' => 'mc9',
		'mc1010' => 'mc10',
		'mc1011' => 'mc11',
		'mc1012' => 'mc12',
		'mc1013' => 'mc13',
		'mc1014' => 'mc14',
		'mc1015' => 'mc15',
		'mc1016' => 'mc16',
	}

	include role::memcached

	file { "/a":
		ensure => directory;
	}

	class { "redis":
		maxmemory         => "500Mb",
		redis_replication => $redis_replication,
	}
	include redis::ganglia
}


node "mchenry.wikimedia.org" {
	$gid = 500

	interface_ip { "dns::recursor": interface => "eth0", address => "208.80.152.132" }

	include base,
		ganglia,
		ntp::client,
		dns::recursor::statistics,
		nrpe,
		role::ldap::client::corp,
		backup::client,
		groups::wikidev,
		accounts::jdavis

	include network::constants

	class { "dns::recursor":
		listen_addresses => ["208.80.152.132"],
		allow_from => $network::constants::all_networks
	}

	dns::recursor::monitor { "208.80.152.132": }
}

node /mobile100[1-4]\.wikimedia\.org/ {
	include newstandard
}

node /ms[1-3]\.pmtpa\.wmnet/ {
	include	standard

	#interface_aggregate { "bond0": orig_interface => "eth0", members => [ "eth0", "eth1" ] }
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

node /^ms(10|1001)\.wikimedia\.org$/ {
	include standard,
		role::mirror::media
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

node /^ms-fe[1-4]\.pmtpa\.wmnet$/ {
	if $hostname =~ /^ms-fe[12]$/ {
		$ganglia_aggregator = "true"
	}
	if $hostname =~ /^ms-fe1$/ {
		include role::swift::pmtpa-prod::ganglia_reporter
	}

	class { "lvs::realserver": realserver_ips => [ "10.2.1.27" ] }

	include role::swift::pmtpa-prod::proxy
}

node /^ms-be(1|2|4|13)\.pmtpa\.wmnet$/ {
	$all_drives = [ '/dev/sdc', '/dev/sdd', '/dev/sde',
		'/dev/sdf', '/dev/sdg', '/dev/sdh', '/dev/sdi', '/dev/sdj', '/dev/sdk',
		'/dev/sdl' ]

	include role::swift::pmtpa-prod::storage

	swift::create_filesystem{ $all_drives: partition_nr => "1" }
}

node /^ms-be9\.pmtpa\.wmnet$/ {
	# the ms-be hosts with ssds have two more disks
	$all_drives = [ '/dev/sdc', '/dev/sdd', '/dev/sde',
		'/dev/sdf', '/dev/sdg', '/dev/sdh', '/dev/sdi', '/dev/sdj', '/dev/sdk',
		'/dev/sdl', '/dev/sdm', '/dev/sdn' ]

	include role::swift::pmtpa-prod::storage

	swift::create_filesystem{ $all_drives: partition_nr => "1" }
}

node /^ms-be(3|[5-8]|10)\.pmtpa\.wmnet$/ {
	# the ms-be hosts that are 720xds with ssds have two more disks
	# but they show up as m and n, those get the OS
	$all_drives = [ '/dev/sda', '/dev/sdb', '/dev/sdc', '/dev/sdd',
		'/dev/sde', '/dev/sdf', '/dev/sdg', '/dev/sdh', '/dev/sdi', '/dev/sdj',
		'/dev/sdk', '/dev/sdl' ]

	include role::swift::pmtpa-prod::storage

	swift::create_filesystem{ $all_drives: partition_nr => "1" }
	# these are already partitioned and xfs formatted by the installer
	swift::label_filesystem{ '/dev/sdm3': }
	swift::label_filesystem{ '/dev/sdn3': }
	swift::mount_filesystem{ '/dev/sdm3': }
	swift::mount_filesystem{ '/dev/sdn3': }
}


node /^ms-be1([1-2]|[4-9])\.pmtpa\.wmnet$/ {
	# the ms-be hosts with ssds have two more disks
	$all_drives = [ '/dev/sdc', '/dev/sdd', '/dev/sde',
		'/dev/sdf', '/dev/sdg', '/dev/sdh', '/dev/sdi', '/dev/sdj', '/dev/sdk',
		'/dev/sdl', '/dev/sdm', '/dev/sdn' ]

	include role::swift::pmtpa-prod::storage

	swift::create_filesystem{ $all_drives: partition_nr => "1" }
}

node /^ms-fe100[1-4]\.eqiad\.wmnet$/ {
	$cluster = "ceph"

	if $hostname =~ /^ms-fe100[12]$/ {
		$ganglia_aggregator = "true"
	}
	class { "lvs::realserver": realserver_ips => [ "10.2.2.27" ] }

	include standard
}

node /^ms-be10[01][0-9]\.eqiad\.wmnet$/ {
	$cluster = "ceph"

	include standard
}

node /^ms-be300[1-4]\.esams\.wikimedia\.org$/ {
	$cluster = "ceph"

	if $::hostname =~ /^ms-be300[12]$/ {
		$ganglia_aggregator = "true"
	}

	include standard
}

# mw1-16 are application servers for jobrunners only (precise)
node /mw([1-9]|1[0-6])\.pmtpa\.wmnet/ {
	if $hostname =~ /^mw[12]$/ {
		$ganglia_aggregator = "true"
	}

	include	role::applicationserver::jobrunner
}

# mw17-59 are application servers (precise)
node /mw(1[7-9]|[2-5][0-9])\.pmtpa\.wmnet$/ {
	include	role::applicationserver::appserver
	include	nfs::upload
}

# mw60-61 are bits application servers (precise)
node /mw6[01]\.pmtpa\.wmnet/ {
	include role::applicationserver::appserver::bits
}

# mw62-74 are api application servers (precise)
node /mw(6[2-9]|7[0-4])\.pmtpa\.wmnet$/ {
	include	role::applicationserver::appserver::api
	include	nfs::upload
}

# mw 1001-1016 are jobrunners (precise)
node /mw10(0[1-9]|1[0-6])\.eqiad\.wmnet/ {
	if $hostname =~ /^mw100[12]$/ {
		$ganglia_aggregator = "true"
	}

	include	role::applicationserver::jobrunner
}

# mw 1017-1113 are apaches (precise)
node /mw1(01[7-9]|0[2-9][0-9]|10[0-9]|11[0-3])\.eqiad\.wmnet/ {
	if $hostname =~ /^mw101[78]$/ {
		$ganglia_aggregator = "true"
	}

	include	role::applicationserver::appserver
}

# mw 1114-1148 are api apaches (precise)
node /mw11(1[4-9]|[23][0-9]|4[0-8])\.eqaid\.wmnet/ {
	if $hostname =~ /^mw111[45]$/ {
		$ganglia_aggregator = "true"
	}

	include	role::applicationserver::appserver::api
}

# mw 1149-1152 are bits apaches (precise)
node /mw11(49]|5[0-2])\.eqiad\.wmnet/ {
	if $hostname =~ /^mw115[12]$/ {
		$ganglia_aggregator = "true"
	}

	include	role::applicationserver::appserver::bits
}

# mw 1153-1160 are imagescalers (precise)
node /mw11(5[3-9]|60)\.eqaid\.wmnet/ {
	if $hostname =~ /^mw115[34]$/ {
		$ganglia_aggregator = "true"
	}

	include	role::applicationserver::imagescaler
}

node "neon.wikimedia.org" {
	$domain_search = "wikimedia.org pmtpa.wmnet eqiad.wmnet esams.wikimedia.org"

	$ircecho_infile = "/var/log/nagios/irc.log"
	$ircecho_nick = "icinga-wm"
	$ircecho_chans = "#wikimedia-operations"
	$ircecho_server = "irc.freenode.net"
	include standard,
		icinga::monitor,
		misc::ircecho
}

node "nescio.esams.wikimedia.org" {
	interface_ip { "dns::auth-server": interface => "eth0", address => "91.198.174.4" }
	interface_ip { "dns::recursor": interface => "eth0", address => "91.198.174.6" }

	include standard,
		dns::recursor::statistics

	class { "dns::auth-server":
		ipaddress => "91.198.174.4",
		soa_name => "ns2.wikimedia.org",
		master => $dns_auth_master
	}

	include network::constants

	class { "dns::recursor":
		listen_addresses => [ "91.198.174.6" ],
		allow_from => $network::constants::all_networks
	}

	dns::recursor::monitor { "91.198.174.6": }

}

node /^nfs[12].pmtpa.wmnet/ {

	$server_bind_ips = "127.0.0.1 $ipaddress_eth0"
	$cluster = "misc"

	include standard,
		misc::nfs-server::home::rsyncd,
		misc::syslog-server,
		role::ldap::server::production,
		# The production ldap is just a replica of labs
		role::ldap::client::labs,
		backup::client

	# don't need udp2log monitoring on nfs hosts
	class { "role::logging::mediawiki":
		monitor => false,
		log_directory => "/home/wikipedia/logs"
	}

}

node "nickel.wikimedia.org" {
	$ganglia_aggregator = "true"

	include standard,
		ganglia::web,
		generic::apache::no-default-site

	 install_certificate{ "star.wikimedia.org": }
}

node /^ocg[1-3]\.wikimedia\.org$/ {

	# online collection generator

	system_role { "misc::mwlib": description => "offline collection generator" }

	include	standard,
		admins::roots,
		misc::mwlib::packages,
		misc::mwlib::users

}

node /^osm-cp100[1-4]\.wikimedia\.org$/ {
	include newstandard
}

node /^owa[1-3]\.wikimedia\.org$/ {
	# taking owa hosts out of the swift proxy cluster since they're not being used.
	# if we have load issues we can add them back in.
	### the hosts are still doing pmtpa-test, but I'm taking out the role to not overwrite local perf testing changes.
	#include role::swift::pmtpa-test::proxy
	include groups::wikidev,
		accounts::darrell,
		accounts::orion,
		accounts::smerritt,
		accounts::john
	sudo_user { [ "darrell" ]: privileges => ['ALL = NOPASSWD: ALL'] }
	sudo_user { [ "orion" ]: privileges => ['ALL = NOPASSWD: ALL'] }
	sudo_user { [ "smerritt" ]: privileges => ['ALL = NOPASSWD: ALL'] }
	sudo_user { [ "john" ]: privileges => ['ALL = NOPASSWD: ALL'] }
}

# base_analytics_logging_node is defined in role/logging.pp
node "oxygen.wikimedia.org"  inherits "base_analytics_logging_node" {
	include
		accounts::awjrichards,
		accounts::datasets,
		accounts::dsc,
		accounts::diederik,
		misc::squid-logging::multicast-relay,
		misc::logging::vanadium-relay,
		misc::udp2log

	sudo_user { "otto": privileges => ['ALL = NOPASSWD: ALL'] }

	# oxygen's udp2log instance
	# saves logs mainly in /a/squid
	misc::udp2log::instance { "oxygen":
		multicast     => true,
		# TODO: Move this to /var/log/udp2log
		log_directory => "/a/squid",
		# oxygen's packet-loss.log file is alredy in /var/log/udp2log
		packet_loss_log => "/var/log/udp2log/packet-loss.log",
	}

	# Set up an rsync daemon module for udp2log logrotated
	# archives.  This allows stat1 to copy logs from the
	# logrotated archive directory
	class { "misc::udp2log::rsyncd":
		path    => "/a/squid",
		require => Misc::Udp2log::Instance["oxygen"],
	}

	# udp2log-lucene instance for
	# lucene search logs.  Don't need
	# to monitor packet loss here.
	misc::udp2log::instance { "lucene":
		port                => "51234",
		log_directory       => "/a/log/lucene",
		monitor_packet_loss => false,
	}

	# rsync archived lucene logs over to dataset2
	# These are available for download at http://dumps.wikimedia.org/other/search/
	cron { "search_logs_rsync":
		command => "rsync -r /a/log/lucene/archive/lucene.log*.gz dataset2::search-logs/",
		hour    => '8',
		minute  => '0',
		user    => 'backup',
		ensure => absent,
	}
}

node /^payments[1-4]\.wikimedia\.org$/ {
	$cluster = "payments"

	if $hostname =~ /^payments[12]$/ {
		$ganglia_aggregator = "true"
	}

	system_role { "misc::payments": description => "Fundraising payments server" }

	include base::remote-syslog,
		base::sysctl,
		base::resolving,
		base::motd,
		base::monitoring::host,
		ganglia

	class { "lvs::realserver": realserver_ips => [ "208.80.152.7" ] }

	monitor_service { "https": description => "HTTPS", check_command => "check_ssl_cert!payments.wikimedia.org" }
}

node /pc([1-3]\.pmtpa|100[1-3]\.eqiad)\.wmnet/ {
  include role::db::core,
    mysql::mysqluser,
    mysql::datadirs,
    mysql::pc::conf,
    mysql::packages

  system_role { "mysql::pc::conf": description => "parser cache mysql server" }
}

node "pdf1.wikimedia.org" {
	$ganglia_aggregator = "true"
	$cluster = "pdf"

	include	role::pdf,
		groups::wikidev,
		accounts::file_mover
}

node "pdf2.wikimedia.org" {
	$ganglia_aggregator = "true"
	$cluster = "pdf"

	include	role::pdf,
		groups::wikidev,
		accounts::file_mover
}

node "pdf3.wikimedia.org" {
	$cluster = "pdf"

	include	role::pdf,
		groups::wikidev,
		accounts::file_mover
}

node "professor.pmtpa.wmnet" {
	$cluster = "misc"
	include base,
		ganglia,
		ntp::client,
		mediawiki::udpprofile::collector,
		misc::graphite
}

node "project1.wikimedia.org" {
	$cluster = "misc"

	include standard
}

node "potassium.eqiad.wmnet" {
	include standard,
		role::poolcounter
}

node "sanger.wikimedia.org" {
	$gid = 500

	include base,
		ganglia,
		ntp::client,
		nrpe,
		role::ldap::server::corp,
		role::ldap::client::corp,
		groups::wikidev,
		accounts::jdavis,
		backup::client

	## hardy doesn't support augeas, so we can't do this. /stab
	#include ldap::server::iptables
}

node /search1[3-8]\.pmtpa\.wmnet/ {
	if $hostname =~ /^search1(3|4)$/ {
		$ganglia_aggregator = "true"
	}

	include role::lucene::front_end::pool4
}

node /search(19|20)\.pmtpa\.wmnet/ {

	include role::lucene::front_end::prefix
}

node /search2[1-6]\.pmtpa\.wmnet/ {

	include role::lucene::front_end::pool1
}

node /search(2[7-9]|30)\.pmtpa\.wmnet/ {

	include role::lucene::front_end::pool2
}

node /search3[1-6]\.pmtpa\.wmnet/ {

	include role::lucene::front_end::pool3
}

node /search100[0-6]\.eqiad\.wmnet/ {
	if $hostname =~ /^search100(1|2)$/ {
		$ganglia_aggregator = "true"
	}

	include role::lucene::front_end::pool1
}

node /search10(0[7-9]|10)\.eqiad\.wmnet/ {

	include role::lucene::front_end::pool2
}

node /search101[1-4]\.eqiad\.wmnet/ {

	include role::lucene::front_end::pool3
}

node /search101[56]\.eqiad\.wmnet/ {

	include role::lucene::front_end::pool4
}

node /search101[78]\.eqiad\.wmnet/ {

	include role::lucene::front_end::prefix
}

node /search10(19|2[0-2])\.eqiad\.wmnet/ {

	include role::lucene::front_end::pool4
}

node /search102[3-4]\.eqiad\.wmnet/ {

	include role::lucene::front_end::pool3
}

node /searchidx100[0-2]\.eqiad\.wmnet/ {

	include role::lucene::indexer
}

node "searchidx2.pmtpa.wmnet" {

	include role::lucene::indexer
}

node "silver.wikimedia.org" {
	include standard,
		groups::wikidev,
		accounts::preilly,
		mobile::vumi
}

node "singer.wikimedia.org" {
	$cluster = "misc"
	$gid=500
	include standard,
		svn::client,
		groups::wikidev,
		accounts::awjrichards,
		generic::mysql::packages::client,
		misc::planet,
		misc::secure


	install_certificate{ "star.wikimedia.org": }
	monitor_service { "secure cert": description => "Certificate expiration", check_command => "check_cert!secure.wikimedia.org!443!Equifax_Secure_CA.pem", critical => "true" }
}

node "sockpuppet.pmtpa.wmnet" {
	include passwords::puppet::database

	include standard,
		backup::client,
		misc::management::ipmi,
		role::salt::masters::production,
		role::deployment::salt_masters::production

	class { puppetmaster:
		allow_from => [ "*.wikimedia.org", "*.pmtpa.wmnet", "*.eqiad.wmnet" ],
		config => {
			'dbadapter' => "mysql",
			'dbuser' => "puppet",
			'dbpassword' => $passwords::puppet::database::puppet_production_db_pass,
			'dbserver' => "db9.pmtpa.wmnet"
		}
	}
}

node "sodium.wikimedia.org" {

	$nameservers_prefix = [ $ipaddress ]

	include base,
		ganglia,
		ntp::client,
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
	$ircecho_chans = "#wikimedia-operations"
	$ircecho_server = "irc.freenode.net"

	include standard,
		nagios::monitor,
		nagios::monitor::pager,
		nagios::monitor::jobqueue,
		nagios::monitor::snmp,
		nagios::monitor::firewall,
		nagios::ganglia::monitor::enwiki,
		nagios::ganglia::ganglios,
		nagios::nsca::daemon,
		nagios::monitor::checkpaging,
		nfs::netapp::home,
		admins::roots,
		admins::mortals,
		certificates::wmf_ca,
		backup::client,
		misc::ircecho

	install_certificate{ "star.wikimedia.org": }
}

# srv190-192 are application servers (precise)
node /^srv19[0-2]\.pmtpa\.wmnet$/ {
	include	role::applicationserver::appserver
	include	nfs::upload
}

# srv193 is test.wikipedia.org (precise)
node "srv193.pmtpa.wmnet" {
	include	role::applicationserver::appserver
	include	nfs::upload
	include nfs::netapp::home,
		memcached
}

# srv194-199 are application servers (precise)
node /^srv19[4-9]\.pmtpa\.wmnet$/ {
	include	role::applicationserver::appserver
	include	nfs::upload
}

# srv200-213 are application servers (precise)
node /^srv(20[0-9]|21[0-3])\.pmtpa\.wmnet$/ {
	include	role::applicationserver::appserver
	include	nfs::upload
}

# srv214-218 are API application servers (precise)
node /^srv21[4-8]\.pmtpa\.wmnet$/ {
	include	role::applicationserver::appserver::api
	include	nfs::upload
}

# srv219-224 are precise image scalers (precise)
node /^srv(219|22[0-4])\.pmtpa\.wmnet$/ {
	if $hostname =~ /^srv219|srv220$/ {
		$ganglia_aggregator = "true"
	}

	include role::applicationserver::imagescaler
	include nfs::upload
}

# srv225-230 are applicationservers (precise)
node /^srv(22[5-9]|230)\.pmtpa\.wmnet$/ {
	include	role::applicationserver::appserver
	include	nfs::upload
}

# srv231-247 are application servers (precise)
node /^srv(23[1-9]|24[0-7])\.pmtpa\.wmnet$/ {
	include	role::applicationserver::appserver
	include	nfs::upload
}

# srv248-249 are bits application servers (precise)
node /^srv24[89]\.pmtpa\.wmnet$/ {
	$ganglia_aggregator = "true"
	include role::applicationserver::appserver::bits
}

# srv250-257 are API application servers (precise)
node /^srv25[0-7]\.pmtpa\.wmnet$/ {
	if $hostname =~ /^srv25[45]$/ {
		$ganglia_aggregator = "true"
	}
	include	role::applicationserver::appserver::api
	include	nfs::upload
}

# srv258-289 are applicationservers (precise)
node /^srv(25[89]|2[6-8][0-9])\.pmtpa\.wmnet$/ {
	if $hostname =~ /^srv25[89]$/ {
		$ganglia_aggregator = "true"
	}

	include	role::applicationserver::appserver
	include	nfs::upload
}

# srv290-301 are API application servers (precise)
node /^srv(29[0-9]|30[01])\.pmtpa\.wmnet$/ {
	include	role::applicationserver::appserver::api
	include	nfs::upload
}

node /ssl[1-4]\.wikimedia\.org/ {
	if $hostname =~ /^ssl[12]$/ {
		$ganglia_aggregator = "true"
	}

	include protoproxy::ssl

	interface_add_ip6_mapped { "main": interface => "eth0" }
}

node /ssl100[1-4]\.wikimedia\.org/ {
	if $hostname =~ /^ssl100[12]$/ {
		$ganglia_aggregator = "true"
	}

	interface_add_ip6_mapped { "main": interface => "eth0" }

	include protoproxy::ssl
}

node /ssl300[1-4]\.esams\.wikimedia\.org/ {
	if $hostname =~ /^ssl300[12]$/ {
		$ganglia_aggregator = "true"
	}

	interface_add_ip6_mapped { "main": interface => "eth0" }

	include protoproxy::ssl

	if $hostname =~ /^ssl3001$/ {
		include protoproxy::ipv6_labs
	}
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

	interface_aggregate { "bond0":
		orig_interface => "eth0",
		members => [ "eth0", "eth1", "eth2", "eth3" ]
	}

	interface_add_ip6_mapped { "main":
		require => Interface_aggregate[bond0],
		interface => "bond0"
	}

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
			'dbconnections' => "256",
			'filesdir' => "/var/lib/git/operations/puppet/files",
			'privatefilesdir' => "/var/lib/git/operations/private/files",
			'manifestdir' => "/var/lib/git/operations/puppet/manifests",
			'modulepath' => "/var/lib/git/operations/puppet/modules",
			'templatedir' => "/var/lib/git/operations/puppet/templates",
			'softwaredir' => "/var/lib/git/operations/software"
		}
	}
}


node "stat1.wikimedia.org" {
	include role::statistics::cruncher

	# special accounts
	include accounts::ezachte,
		accounts::reedy,
		accounts::diederik,
		accounts::otto,
		accounts::aengels,
		accounts::dsc,
		accounts::akhanna,
		accounts::dartar,
		accounts::declerambaul,
		accounts::jmorgan,
		accounts::rfaulk,
		# RT 3219
		accounts::haithams,
		# RT 3119
		admins::globaldev,
		# RT 3451
		accounts::olivneh,
		accounts::spage,
		# RT 3460
		accounts::giovanni,
		accounts::halfak,
		# RT 3517
		accounts::maryana,
		# RT 3540
		accounts::dandreescu,
		# RT 3576
		accounts::howief,
		# RT 3584
		accounts::spetrea,
		# RT 3653
		accounts::swalling,
		# RT 4106
		accounts::abartov,
		accounts::ironholds,
		accounts::jdlrobson,
		accounts::jgonera


	sudo_user { "otto": privileges => ['ALL = NOPASSWD: ALL'] }
}

node "stat1001.wikimedia.org" {
	include role::statistics::www

	# special accounts
	include accounts::ezachte,
		accounts::diederik,
		accounts::otto,
		accounts::dsc,
		accounts::dandreescu

	sudo_user { "otto": privileges => ['ALL = NOPASSWD: ALL'] }
}

node "storage1.wikimedia.org" {

	include standard
}

node "storage2.wikimedia.org" {
	include standard
}

node "streber.wikimedia.org" {
	system_role { "misc": description => "network monitoring server" }

	include	passwords::root,
		base::decommissioned,
		base::resolving,
		base::sysctl,
		base::motd,
		base::vimconfig,
		base::standard-packages,
		base::monitoring::host,
		base::environment,
		base::platform,
		ssh,
		ganglia,
		ntp::client,
		admins::roots,
#		misc::torrus,
		exim::rt,
		misc::rt::server,
		misc::rancid,
		firewall::builder

	class { "misc::syslog-server": config => "network" }

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
		sudo::appserver,
		admins::roots,
		admins::mortals,
		accounts::datasets,
		nfs::data,
		groups::wikidev
}

node "thistle.pmtpa.wmnet" {
	$ganglia_aggregator = "true"
	include role::db::core
}

node "tin.eqiad.wmnet" {
	$cluster = "misc"
	$domain_search = "wikimedia.org pmtpa.wmnet eqiad.wmnet esams.wikimedia.org"

	include standard,
		admins::roots,
		admins::mortals,
		role::deployment::deployment_servers::production
}

node "tridge.wikimedia.org" {
	include base,
		backup::server
}

# tmh1/tmh2 video encoding server (precise only)
node /^tmh[12]\.pmtpa\.wmnet$/ {
	if $hostname =~ /^tmh[12]$/ {
		$ganglia_aggregator = "true"
	}

	include	role::applicationserver::videoscaler,
		nfs::upload
}

node "vanadium.eqiad.wmnet" {
	$gid=500
	system_role { "misc::log-collector": description => "log collector" }

	include standard,
		groups::wikidev,
		admins::restricted,
		accounts::aaron,
		accounts::datasets,
		accounts::dsc,
		accounts::diederik,
		accounts::mflaschen,
		accounts::maryana,
		accounts::rfaulkner,
		accounts::spage,
		misc::statistics::db::mysql,
		misc::statistics::db::mongo,
		redis::ganglia,
		nrpe,
		role::solr::ttm

	sudo_user { [ "otto", "olivneh", "spage", "mflaschen" ]:
		privileges => ['ALL = (ALL) NOPASSWD: ALL']
	}
}

node "virt1000.wikimedia.org" {
	$cluster = "virt"
	$is_puppet_master = "true"
	$is_labs_puppet_master = "true"
	$openstack_version = "essex"

	include standard,
		role::dns::ldap,
		role::ldap::server::labs,
		role::ldap::client::labs,
		role::nova::controller
}

node "virt0.wikimedia.org" {
	$cluster = "virt"

	$is_puppet_master = "true"
	$is_labs_puppet_master = "true"
	$openstack_version = "essex"

	include standard,
		role::dns::ldap,
		role::ldap::server::labs,
		role::ldap::client::labs,
		role::nova::controller,
		role::salt::masters::labs,
		role::deployment::salt_masters::labs,
		backup::client
}

node /virt([2]|[5-9]|1[0-1]).pmtpa.wmnet/ {
	$cluster = "virt"
	if $hostname =~ /^virt[56]$/ {

		$ganglia_aggregator = "true"
	}

	include standard

	$openstack_version = "essex"
	if $hostname =~ /^virt2$/ {
		include role::nova::network,
			role::nova::api
		interface_ip { "openstack::network_service_public_dynamic_snat": interface => "lo", address => "208.80.153.192" }
	}
	include	role::nova::compute
}

node /virt100(5|7|8).eqiad.wmnet/ {
	#$cluster = "virt"
	#if $hostname =~ /^virt100[57]$/ {
	#	$ganglia_aggregator = "true"
	#}

	include standard

	$openstack_version = "essex"
	if $hostname =~ /^virt1005$/ {
		include role::nova::network,
			role::nova::api
		interface_ip { "openstack::network_service_public_dynamic_snat": interface => "lo", address => "208.80.155.255" }
	}
	include	role::nova::compute
}

node "williams.wikimedia.org" {
	include base,
		ganglia,
		ntp::client

	install_certificate{ "star.wikimedia.org": }
}

node /(wtp1|kuo|lardner|mexia|tola)\.pmtpa\.wmnet/ {
	$cluster = "parsoid"
	$nagios_group = "${cluster}_$::site"

	if $hostname == "wtp1" {
		$ganglia_aggregator = "true"
	}

	include standard,
		admins::roots,
		misc::parsoid

	class { "lvs::realserver": realserver_ips => [ "10.2.1.28" ] }

}

node /(celsus|constable)\.wikimedia\.org/ {
	$cluster = "parsoidcache"
	$nagios_group = "${cluster}_$::site"

	if $hostname == "constable" {
		$ganglia_aggregator = "true"
	}

	include standard,
		admins::roots,
		misc::parsoid::cache,
		misc::parsoid
}

node /(caesium|xenon|wtp1001)\.eqiad\.wmnet/ {
	$cluster = "parsoid"
	$nagios_group = "${cluster}_$::site"

	if $hostname == "wtp1001" {
		$ganglia_aggregator = "true"
	}

	include standard,
		admins::roots,
		misc::parsoid

	class { "lvs::realserver": realserver_ips => [ "10.2.2.28" ] }

}

node  "yongle.wikimedia.org" {
	$gid=500
	include	standard,
		groups::wikidev,
		accounts::catrope
}

node /^solr(100)?[1-3]\.(eqiad|pmtpa)\.wmnet/ {
	include standard,
		role::solr::geodata
}

node "yvon.wikimedia.org" {
	include base,
		ganglia,
		ntp::client,
		certificates::wmf_ca
}

node "zhen.wikimedia.org" {
	include standard,
		groups::wikidev,
		accounts::preilly,
		mobile::vumi
}

node "zirconium.wikimedia.org" {
	include standard,
		admins::roots,
		role::planet
}

node default {
	include	standard
}
