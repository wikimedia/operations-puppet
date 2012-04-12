# misc/logging.pp
# any logging hosts

class udp2log {

	class configuration {
		$filters = {
			"locke" => [
				'file 1000 /a/squid/sampled-1000.log',
				'pipe 1 /a/webstats/bin/filter | log2udp -h 127.0.0.1 -p 3815', # domas' stuff.
				#'pipe 1 /a/squid/book-filter >> /a/squid/book-log.log', #for book extension (data moved to hume then pdf1 by file_mover daily), disabled by ben 2011-10-25 due to load 
				'pipe 100 /a/squid/m-filter >> /a/squid/mobile.log', #for mobile traffic
				'pipe 10 /a/squid/india-filter >> /a/squid/india.log', #india
				#'pipe 1 /a/webstats/bin/filter > /dev/null', # for debugging
				#'file 1000 /home/file_mover/test/bannerImpressions.log', #for testing
				'pipe 1 /a/squid/fundraising/lp-filter >> /a/squid/fundraising/logs/landingpages.log', #Fundraising:  Landing pages
				'pipe 1 /a/squid/fundraising/bi-filter >> /a/squid/fundraising/logs/bannerImpressions.log', #Fundraising: Banner Impressions
				#'pipe 1 /a/squid/acctcreation/ac-filter >> /a/squid/acctcreation.log', # Account creation/signup stats DISABLED -nimish- 11/19
				'pipe 10 awk -f /a/squid/vu.awk | log2udp -h 130.37.198.252 -p 9999', # Vrije Universiteit, Contact: <%= scope.lookupvar('contacts::udp2log::vrije_universiteit_contact') %>
				'pipe 100 awk -f /a/squid/urjc.awk | log2udp -h wikilogs.libresoft.es -p 10514', # Universidad Rey Juan Carlos Contact: <%= scope.lookupvar('contacts::udp2log::universidad_rey_juan_carlos_contact') %>
				# Backup contact: <%= scope.lookupvar('contacts::udp2log::universidad_rey_juan_carlos_backup_contact') %>
				'pipe 10 awk -f /a/squid/minnesota.awk | log2udp -h bento.cs.umn.edu -p 9999', # University of Minnesota Contact: <%= scope.lookupvar('contacts::udp2log::university_minnesota_contact') %>
				# Former Contact: <%= scope.lookupvar('contacts::udp2log::university_minnesota_contact_former') %> Former contact: <%= scope.lookupvar('contacts::udp2log::university_minnesota_contact_former2') %>
				#'pipe 1 awk '$5 == "208.94.116.204" {print $0}' > /a/squid/watchlistr.log', # Investigating watchlistr.com -- TS
				#'pipe 1 awk '$9 ~ "/w/api\.php.*action=login" {print $0}' >> /a/squid/api.log', 
				#'pipe 1 awk '$7 > 10000000 {print $0}' | geoiplogtag 5 >> /a/squid/large-requests.log', # Investigate who's using up 1 Gbps of bandwidth all the time: DISABLED -nimish- 11/19
				'pipe 1 /a/squid/edits-filter >> /a/squid/edits.log', # All edits
				#'pipe 1 awk '$9 ~ "/wiki/Special:Book" { print $0 }' >> /a/squid/special-book.log', # All requetsts for [[Special:Book]]
				'pipe 1 /a/squid/5xx-filter | awk -W interactive '$9 !~ "upload.wikimedia.org|query.php"' >> /a/squid/5xx.log,' # All 5xx error responses -- domas
				#'pipe 1 awk -f /a/squid/support.awk >> /a/squid/support-requests.log', # Logging Support requests -- fred
				#'pipe 1 awk '$6 ~ "/301$" && ( $9 ~ "/wiki/." || $9 ~ "/w/index\.php\?" ) { print $9 }' | tee /a/squid/self-redirects.log | php /root/purgeListStandalone.php', # Find redirects and purge them (TEMP)
				#'pipe 1 awk '$5 == "84.45.45.135" {print $0}' >> /a/squid/wikigalore.log', # Remote loader investigation (TEMP)
				#'pipe 1 awk '$9 ~ "^http://(en|es|ru|pl|pt|de|nl|fr|ja|it|commons)\.wiki[pm]edia\.org" { print $9 }' | python /root/dampen.py /a/tmp/vector-purge-cache 25000 | tee /a/squid/vector.log | php /root/purgeListStandalone.php', # (TEMP) Vector migration
				#'pipe 1 awk '$9 ~ "^http://(en|es|ru|pl|pt|de|nl|fr|ja|it|commons)\.wiki[pm]edia\.org" { print $9 }' | log2udp -h 127.0.0.1 -p 5844',
				#'python /root/dampen.py /a/tmp/vector-purge-cache 25000 | tee /a/squid/vector.log | php /root/purgeListStandalone.php',
				'pipe 10 /usr/local/bin/packet-loss 10 >> /a/squid/packet-loss.log,' # Monitor packet loss -- Tim
			],
			"locke_aft" => [
				'file 1 /var/log/aft/clicktracking.log',
			],
			"emery" => [
				'file 1000 /var/log/squid/sampled-1000.log',
				'pipe 1000 /var/log/squid/filters/latlongCountry-writer >> /var/log/squid/location-1000.log',
				'pipe 2 /usr/local/bin/sqstat 2',
				'pipe 10 /var/log/squid/filters/india-filter >> /var/log/squid/india.log',
				'pipe 10 /usr/local/bin/packet-loss 10 >> /var/log/squid/packet-loss.log',
				'pipe 100 /var/log/squid/filters/api-filter >> /var/log/squid/api-usage.log',
				#'pipe 1 /var/log/squid/filters/mobile-offline-meta >> /var/log/squid/mobile-offline-meta.log', # this filter is segfaulting repeatedly.  tomasz says he doesn't need it at the moment -ben 2011-11-01
				'pipe 10 mawk '{ if ($9 ~ /_(NARA|National_Archives)_.*\.(jpg|tif)/) { print $3,$9,$12} }' >> /var/log/squid/glam_nara.log', # RT 2212
				'pipe 1 /usr/bin/udp-filter -f -c CD,CF,CI,GQ -g -m /var/log/squid/filters/GeoIPLibs/GeoIP.dat -b country >> /var/log/squid/countries-1.log', #specific country filters - 2012-01-24 through 2012-02-20 then ask Nimish  or Amit if we still need them
				'pipe 10 /usr/bin/udp-filter -f -c KH,BW,CM,MG,ML,MU,NE,VU -g -m /var/log/squid/filters/GeoIPLibs/GeoIP.dat -b country >> /var/log/squid/countries-10.log', #specific country filters - 2012-01-24 through 2012-02-20 then ask Nimish  or Amit if we still need them
				'pipe 100 /usr/bin/udp-filter -f -c BD,BH,IQ,JO,KE,KW,LK,NG,QA,SN,TN,UG,ZA -g -m /var/log/squid/filters/GeoIPLibs/GeoIP.dat -b country >> /var/log/squid/countries-100.log', #specific country filters - 2012-01-24 through 2012-02-20 then ask Nimish  or Amit if we still need them
				'pipe 10 /usr/bin/udp-filter -i 203.92.128.185,115.164.0.0-115.164.255.255,116.197.0.0-116.197.127.255 >> /var/log/squid/digi-malaysia.log', #specific Wikipedia Zero filters: Digi Malaysia
				'pipe 10 /usr/bin/udp-filter -i 41.66.28.94,41.66.28.95,41.66.28.96,41.66.28.72,41.66.28.73,172.23.0.0-172.23.255.255 >> /var/log/squid/orange-ivory-coast.log', #specific Wikipedia Zero filters: Orange Ivory Coast
				'pipe 10 /usr/bin/udp-filter -d en.wikipedia.org -p /wiki/Wikipedia:Teahouse >> /var/log/squid/teahouse.log', #Teahouse filters
			],
			"emery_aft" => [
				'file 1 /var/log/aft/clicktracking.log',
			],
			"oxygen" => [
				'file 1000 /var/log/squid/sampled-1000.log',
			],
		}
	}

	class logger( $log_file, $has_aft=true ) {

		include contacts::udp2log
		include udp2log::monitoring
		include udp2log::iptables
		if ( $udp2log::logger::has_aft == true ) {
			include udp2log::aft
		}

		system_role { "misc::mediawiki-logger": description => "MediaWiki log server" }

		package { ["udplog", "udp-filter"]:
			ensure => latest;
		}

		package { udp-filters:
			ensure => absent;
		}

		file {
		## NOTE: this change will require a change to the init script on emery
		## to point it at the right place for the config file
			"/etc/udp2log/squid":
				require => Package[udplog],
				mode => 0444,
				owner => root,
				group => root,
				content => template("udp2log/udp2log.filters.erb");
			"/etc/udp2log":
				require => Package[udplog],
				mode => 0444,
				owner => root,
				group => root,
				content => "flush pipe 1 python /usr/local/bin/demux.py\n";
			"/usr/local/bin/demux.py":
				mode => 0544,
				owner => root,
				group => root,
				source => "puppet:///files/misc/demux.py";
			"/etc/logrotate.d/mw-udp2log":
				source => "puppet:///files/logrotate/mw-udp2log",
				mode => 0444;
			"/etc/sysctl.d/99-big-rmem.conf":
				owner => "root",
				group => "root",
				mode => 0444,
				content => "net.core.rmem_max = 536870912";
			"/usr/local/bin/sqstat":
				mode => 0555,
				owner => root,
				group => root,
				source => "puppet:///files/udp2log/sqstat.pl"
		}

		service { udp2log:
			require => [ Package[udplog], File[ ["/etc/udp2log", "/usr/local/bin/demux.py"] ] ],
			subscribe => File["/etc/udp2log"],
			ensure => running;
		}
	}

	class aft {

		system_role { "misc::mediawiki-logger-aft": description => "MediaWiki log server aux process" }

		file {
			"/etc/udp2log/aft":
				require => Package[udplog],
				mode => 0444,
				owner => root,
				group => root,
				content => template("udp2log/udp2log.filters.aft.erb");
			"/etc/init.d/udp2log-aft":
				mode => 0555,
				owner => root,
				group => root,
				source => "puppet:///files/udp2log/udp2log-aft";
			"/etc/logrotate.d/aft-udp2log":
				mode => 0444,
				source => "puppet:///files/logrotate/aft-udp2log";
		}

		service {
			"udp2log-aft":
				ensure => running,
				enable => true,
				require => File["/etc/init.d/udp2log-aft"];
		}
	}

	class monitoring {
		Class["udp2log::logger"] -> Class["udp2log::monitoring"]

		include udp2log::iptables

		package { "ganglia-logtailer":
			ensure => latest;
		}

		file {
			"/etc/nagios/nrpe.d/nrpe_udp2log.cfg":
				require => Package[nagios-nrpe-server],
				mode => 0440,
				owner => root,
				group => nagios,
				source => "puppet:///files/nagios/nrpe_udp2log.cfg";
			"/usr/lib/nagios/plugins/check_udp2log_log_age":
				mode => 0555,
				owner => root,
				group => root,
				source => "puppet:///files/nagios/check_udp2log_log_age";
			"/usr/lib/nagios/plugins/check_udp2log_procs":
				mode => 0555,
				owner => root,
				group => root,
				source => "puppet:///files/nagios/check_udp2log_procs";
			"PacketLossLogtailer.py":
				path => "/usr/share/ganglia-logtailer/PacketLossLogtailer.py",
				mode => 0444,
				owner => root,
				group => root,
				source => "puppet:///files/misc/PacketLossLogtailer.py";
		}

		cron {
			"ganglia-logtailer" :
				ensure => present,
				command => "/usr/sbin/ganglia-logtailer --classname PacketLossLogtailer --log_file $log_file --mode cron",
				user => 'root',
				minute => '*/5';
		}

		monitor_service { "udp2log log age": description => "udp2log log age", check_command => "nrpe_check_udp2log_log_age" }
		monitor_service { "udp2log procs": description => "udp2log processes", check_command => "nrpe_check_udp2log_procs" }
		monitor_service { "packetloss": description => "Packetloss_Average", check_command => "check_packet_loss_ave!4!8" }
	}

	class iptables_purges {
		require "iptables::tables"
		# The deny rule must always be purged, otherwise ACCEPTs can be placed below it
		iptables_purge_service{ "udp2log_drop_udp": service => "udp" }
		# When removing or modifying a rule, place the old rule here, otherwise it won't
		# be purged, and will stay in the iptables forever
	}

	class iptables_accepts {
		require "udp2log::iptables_purges"
		# Rememeber to place modified or removed rules into purges!
		# common services for all hosts
		iptables_add_service{ "udp2log_accept_all_private": service => "all", source => "10.0.0.0/8", jump => "ACCEPT" }
		iptables_add_service{ "udp2log_accept_all_US": service => "all", source => "208.80.152.0/22", jump => "ACCEPT" }
		iptables_add_service{ "udp2log_accept_all_AMS": service => "all", source => "91.198.174.0/24", jump => "ACCEPT" }
		iptables_add_service{ "udp2log_accept_all_localhost": service => "all", source => "127.0.0.1/32", jump => "ACCEPT" }
	}

	class iptables_drops {
		require "udp2log::iptables_accepts"
		# Rememeber to place modified or removed rules into purges!
		iptables_add_service{ "udp2log_drop_udp": service => "udp", source => "0.0.0.0/0", jump => "DROP" }
	}

	class iptables  {
	# only allow UDP packets from our IP space into these machines to prevent malicious information injections

		# We use the following requirement chain:
		# iptables -> iptables-drops -> iptables-accepts -> iptables-purges
		#
		# This ensures proper ordering of the rules
		require "udp2log::iptables_drops"
		# This exec should always occur last in the requirement chain.
		## creating iptables rules but not enabling them to test.
		iptables_add_exec{ "udp2log": service => "udp2log" }
	}
}

class misc::syslog-server($config="nfs") {
	system_role { "misc::syslog-server": description => "central syslog server ($config)" }

	package { syslog-ng:
		ensure => latest;
	}

	file { "/etc/syslog-ng/syslog-ng.conf":
		require => Package[syslog-ng],
		source => "puppet:///files/syslog-ng/syslog-ng.conf.${config}",
		mode => 0444;
	}
	
	# FIXME: handle properly
	if $config == "nfs" {
		file { "/etc/logrotate.d/remote-logs":
			source => "puppet:///files/syslog-ng/remote-logs",
			mode => 0444;
		}
	}

	service { syslog-ng:
		require => [ Package[syslog-ng], File["/etc/syslog-ng/syslog-ng.conf"] ],
		subscribe => File["/etc/syslog-ng/syslog-ng.conf"],
		ensure => running;
	}
}

class misc::squid-logging::multicast-relay {
	system_role { "misc::squid-logging::multicast-relay": description => "Squid logging unicast to multicast relay" }

	upstart_job { "squid-logging-multicast-relay": install => "true" }

	package { "socat": ensure => latest; }

	service { squid-logging-multicast-relay:
		require => [ Package[socat], Upstart_job[squid-logging-multicast-relay] ],
		subscribe => Upstart_job[squid-logging-multicast-relay],
		ensure => running;
	}
}

