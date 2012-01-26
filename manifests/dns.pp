# dns.pp
#
# Parameters:
# - $dns_auth_ipaddress:	IP address PowerDNS will bind to and send packets from
# - $dns_auth_soa_name:		DNS SOA name of the server
# - $dns_auth_master:		Which DNS server to use as "master" to fetch zones from

import "generic-definitions.pp"

class dns::auth-server-ldap {

	package { [ "pdns-server", "pdns-backend-ldap" ]:
		ensure => latest;
	}

	# FIXME: parameterize, call from a nova role class, remove this include
	include openstack::nova_config

	$nova_ldap_host = $openstack::nova_config::nova_ldap_host
	$nova_ldap_base_dn = $openstack::nova_config::nova_ldap_base_dn
	$nova_ldap_user_dn = $openstack::nova_config::nova_ldap_user_dn
	$nova_ldap_user_pass = $openstack::nova_config::nova_ldap_user_pass

	# FIXME: remove some duplication between this and dns::auth-server
	if ! $dns_auth_ipaddress {
		fail("Parametmer $dns_auth_ipaddress not defined!")
	}

	if ! $dns_auth_soa_name {
		fail("Parameter $dns_auth_soa_name not defined!")
	}

	system_role { "dns::auth-server-ldap": description => "Authoritative DNS server (LDAP)" }

	file {
		"/etc/powerdns/pdns.conf":
			require => Package["pdns-server"],
			owner => root,
			group => root,
			mode => 0444,
			content => template("powerdns/pdns-ldap.conf.erb"),
			ensure => present;
	}

	service { pdns:
		require => [Package["pdns-server"], File["/etc/powerdns/pdns.conf"]],
		subscribe => File["/etc/powerdns/pdns.conf"],
		hasrestart => false,
		ensure => running;
	}

	# Monitoring
	monitor_host { $dns_auth_soa_name: ip_address => $dns_auth_ipaddress }
	monitor_service { "auth dns": host => $dns_auth_soa_name, description => "Auth DNS", check_command => "check_dns!www.wikipedia.wmflabs.org" }

}

class dns::auth-server($ipaddress="", $soa_name="", $master="") {
	$dns_auth_ipaddress = $ipaddress
	$dns_auth_soa_name = $soa_name
	$dns_auth_master = $master

	if ! $dns_auth_ipaddress {
		fail("Parametmer $dns_auth_ipaddress not defined!")
	}

	if ! $dns_auth_soa_name {
		fail("Parameter $dns_auth_soa_name not defined!")
	}

	if ! $dns_auth_master {
		fail("Parameter $dns_auth_master not defined!")
	}

	package { wikimedia-task-dns-auth:
		ensure => latest;
	}

	system_role { "dns::auth-server": description => "Authoritative DNS server" }

	file {
		"/etc/powerdns/pdns.conf":
			require => Package[wikimedia-task-dns-auth],
			owner => root,
			group => root,
			mode => 0444,
			content => template("powerdns/pdns.conf.erb"),
			ensure => present;
		"/usr/local/lib/selective-answer.py":
			owner => root,
			group => root,
			mode => 0555,
			source => "puppet:///files/powerdns/selective-answer.py",
			ensure => present;
		"/etc/powerdns/participants":
			require => Package[wikimedia-task-dns-auth],
			ensure => present;
		"/root/.ssh/wikimedia-task-dns-auth":
			owner => root,
			group => root,
			mode => 0400,
			source => "puppet:///private/powerdns/wikimedia-task-dns-auth",
			ensure => present;
		"/etc/powerdns/ip-map":
			owner => pdns,
			group => pdns,
			mode => 0755,
			recurse => true;
		# Remove broken cron job
		"/etc/cron.d/wikimedia-task-dns-auth":
			ensure => absent;
	}

	exec { authdns-local-update:
		command => "/usr/sbin/authdns-local-update authdns@${dns_auth_master}",
		require => [ File["/root/.ssh/wikimedia-task-dns-auth"], Package[wikimedia-task-dns-auth] ],
		user => root,
		path => "/usr/sbin",
		returns => [ 0, 1 ],
		refreshonly => true,
		subscribe => Service[pdns],
		timeout => 60;
	}

	service { pdns:
		require => [ Package[wikimedia-task-dns-auth], File["/etc/powerdns/pdns.conf"], Interface_ip["dns::auth-server"] ],
		subscribe => File["/etc/powerdns/pdns.conf"],
		hasrestart => false,
		ensure => running;
	}

	# Publish service ip hostkeys
	@@sshkey {
		"${dns_auth_soa_name}":
			type => ssh-rsa,
			key => $sshrsakey,
			ensure => present;
		"${dns_auth_ipaddress}":
			type => ssh-rsa,
			key => $sshrsakey,
			ensure => present;
	}

	include dns::account

	# Update ip map file

	cron { "update ip map":
		command => "rsync -qt 'rsync://countries-ns.mdc.dk/zone/zz.countries.nerd.dk.rbldnsd' /etc/powerdns/ip-map/zz.countries.nerd.dk.rbldnsd && pdns_control rediscover > /dev/null",
		user => pdns,
		hour => 4,
		minute => 7,
		ensure => present;
	}

	# Monitoring
	monitor_host { $dns_auth_soa_name: ip_address => $dns_auth_ipaddress }
	monitor_service { "auth dns": host => $dns_auth_soa_name, description => "Auth DNS", check_command => "check_dns!www.wikipedia.org" }
}

class dns::recursor {
	if ! $dns_recursor_ipaddress {
		fail("Parameter $dns_recursor_ipaddress not defined!")
	}

	package { pdns-recursor:
		ensure => latest;
	}

	system_role { "dns::recursor": description => "Recursive DNS server" }

	file { "/etc/powerdns/recursor.conf":
		require => Package[pdns-recursor],
		owner => root,
		group => root,
		mode => 0444,
		content => template("powerdns/recursor.conf.erb"),
		ensure => present;
	}

	service { pdns-recursor:
		require => [ Package[pdns-recursor], File["/etc/powerdns/recursor.conf"] ],
		subscribe => File["/etc/powerdns/recursor.conf"],
		name => "pdns_recursor",
		hasstatus => false,
		ensure => running;
	}

	class monitoring {
		# Monitoring
		monitor_host { $dns_recursor_ipaddress: ip_address => $dns_recursor_ipaddress }
		monitor_service { "recursive dns": host => $dns_recursor_ipaddress, description => "Recursive DNS", check_command => "check_dns!www.wikipedia.org" }
	}

	class statistics {
		package { rrdtool:
			ensure => latest;
		}

		file {
			"/usr/local/powerdnsstats":
				source => "puppet:///files/powerdns/recursorstats/scripts",
				recurse => remote;
			"/var/www/pdns":
				source => "puppet:///files/powerdns/recursorstats/www",
				recurse => remote;
		}

		exec { "/usr/local/powerdnsstats/create":
			require => [ Package[rrdtool], File["/usr/local/powerdnsstats"] ],
			cwd => "/var/www/pdns",
			user => root,
			creates => "/var/www/pdns/pdns_recursor.rrd";
		}

		cron { pdnsstats:
			command => "cd /var/www/pdns && /usr/local/powerdnsstats/update && /usr/local/powerdnsstats/makegraphs >/dev/null",
			user => root,
			minute => '*/5';
		}

		# Install a static web server to serve this
		include webserver::static
	}
}

class dns::account {
	systemuser { authdns: name => "authdns", home => "/var/lib/authdns", shell => "/bin/sh" }

	ssh_authorized_key { wikimedia-task-dns-auth:
		key => "AAAAB3NzaC1yc2EAAAABIwAAAgEAxwysYhVb1W0j0MyepYYNZrB0CG3t/4BsOeF3DDx+G0+lwTwdZxmPteHSe68vliz+h5DMN/47hAuvdRkEGtsv2yqXKOPh7dAHsWcG2Tzk4uHF+LQRx1I+9IaxQFnpZ3zphvxdN9yIsSc/44aeZ1PX+DyJIhT/EIIm7Bz7RTOzQikH9yaaRaoZKbYB4Io09gyRC3dSarQw6R8zpyLM6jhqZLu5u3xGwmSWykXb5/jOfZvD/KT0dv07gIhW+sTVvQnZd1YyGMIfDSt5gqnhAlKiuiDBOHWx/Q6zE7Vc7iNiJbSyTZXU5neFy3v7kzwsgkRA6tQaK5CTZYI/gHErogKQqa81Y/iar2Vamh7xG4iNInQGL9k7L81t/5zmPKzg8A6dSSjOfUyWAUtrmKiWyXbvOd6FfxkF7pkBkuCYm7TjtB1Md+VIzzVhRe1yxY1mUcVWlbjKUPk5dxnWkXKHcaUKjagNwbuIAjupKelQSK5vJc1Qt4G/WYK2SnPCk8RJor/+6Cauy5I7blEJhVz9Paaf7MKtQvTLnOyOsla5+ZicY+V8w5HdvYLd+CC4RI4JTVFJjtEQTyzeoNurvpSOe3YZMP12fjHXN6fAPJu97FTusLCABDtFTRAOFXrC2GJqG0eQKx7Npnzq5Cy09HwBwDkZ9AkCQOjdW2e1Z7HD2wqLW2s=",
		type => ssh-rsa,
		user => authdns,
		ensure => present;
	}
}
