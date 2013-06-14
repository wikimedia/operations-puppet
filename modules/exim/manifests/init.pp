# Class: exim
#
# This class installs a full featured Exim MTA
#
# Parameters:
#	- $local_domains:
#		List of domains Exim will treat as "local", i.e. be responsible
#		for
#	- $enable_mail_relay:
#		Values: primary, secondary
#		Whether Exim will act as a primary or secondary mail relay for
#		other mail servers
#	- $enable_mailman:
#		Whether Mailman delivery functionality is enabled (true/false)
#	- $enable_imap_delivery:
#		Whether IMAP local delivery functional is enabled (true/false)
#	- $enable_mail_submission:
#		Enable/disable mail submission by users/client MUAs
#	- $mediawiki_relay:
#		Whether this MTA relays mail for MediaWiki (true/false)
#	- $enable_spamasssin:
#		Enable/disable SpamAssassin spam checking
#	- $outbound_ips:
#		IP addresses to use for sending outbound e-mail
#	- $hold_domains:
#		List of domains to hold on the queue without processing
class exim(
	$local_domains = [ "+system_domains" ],
	$enable_mail_relay="false",
	$enable_mailman="false",
	$enable_imap_delivery="false",
	$enable_mail_submission="false",
	$enable_external_mail="false",
	$smart_route_list=[],
	$mediawiki_relay="false",
	$rt_relay="false",
	$enable_spamassassin="false",
	$outbound_ips=[ $ipaddress ],
	$hold_domains=[] ) {

	class { "exim::config": install_type => "heavy", queuerunner => "combined" }
	Class["exim::config"] -> Class[exim]

	include exim::service

	include exim::smtp
	include network::constants
	include exim::listserve::private

	$primary_mx = [ "208.80.152.186", "2620::860:2:219:b9ff:fedd:c027" ]
	file {
		"/etc/exim4/exim4.conf":
			require => Package[exim4-config],
			notify => Service[exim4],
			owner => root,
			group => Debian-exim,
			mode => 0440,
			content => template("exim/exim4.conf.SMTP_IMAP_MM.erb");
		"/etc/exim4/system_filter":
			owner => root,
			group => Debian-exim,
			mode => 0444,
			content => template("exim/system_filter.conf.erb");
		"/etc/exim4/defer_domains":
			owner => root,
			group => Debian-exim,
			mode => 0444,
			ensure => present;
	}

	if ( $enable_mailman == "true" ) {
		include exim::mailman
	}
	if ( $enable_mail_relay == "primary" ) or ( $enable_mail_relay == "secondary" ) {
		include exim::mail_relay
	}
	if ( $enable_spamassassin == "true" ) {
		include spamassassin
	}
}
