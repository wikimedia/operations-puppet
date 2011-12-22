$iptables_ports = {
	all => "",
	ssh => "22",
	http => "80",
	http-alt => "8080",
	https => "443",
	ntp_tcp => "123",
	ntp_udp => "123",
	rsyncd_tcp => "873",
	rsyncd_udp => "873",
	memcached => "11000",
	memcached-standard => "11211",
	ldap => "389",
	ldap_backend => "1389",
	ldaps => "636",
	ldaps_backend => "1636",
	ldap_admin_connector => "4444",
	mysql => "3306",
	nsca => "5667",
	puppetmaster => "8140",
	icmp => "",
	igmp => "",
	nova_ec2_api => "8773",
	nova_openstack_api => "8774",
	nova_ajax_proxy => "8000",
	swift_account => "6002",
	swift_container => "6001",
	swift_object => "6000",
	glance_api => "9292",
	glance_registry => "9191",
	epmd => "4369",
	beam1 => "33416",
	beam2 => "5672",
	gmond_tcp => "8649",
	gmond_udp => "8649",
	udp => ""
}

$iptables_protocols = {
	all => "all",
	ssh => "tcp",
	http => "tcp",
	http-alt => "tcp",
	https => "tcp",
	ntp_tcp => "tcp",
	ntp_udp => "udp",
	rsyncd_tcp => "tcp",
	rsyncd_udp => "udp",
	memcached => "tcp",
	memcached-standard => "tcp",
	ldap => "tcp",
	ldap_backend => "tcp",
	ldaps => "tcp",
	ldaps_backend => "tcp",
	ldap_admin_connector => "tcp",
	mysql => "tcp",
	nsca => "tcp",
	puppetmaster => "tcp",
	icmp => "icmp",
	igmp => "igmp",
	nova_ec2_api => "tcp",
	nova_openstack_api => "tcp",
	nova_ajax_proxy => "tcp",
	swift_account => "tcp",
	swift_container => "tcp",
	swift_object => "tcp",
	glance_api => "tcp",
	glance_registry => "tcp",
	epmd => "tcp",
	beam1 => "tcp",
	beam2 => "tcp",
	gmond_tcp => "tcp",
	gmond_udp => "udp",
	udp => "udp"
}

class iptables::tables {

	augeas { "$hostname iptables tables":
		context => "/files/etc/iptables-save",
		changes => [ "set table[1] nat", "set table[2] filter" ];
	}

	augeas { "$hostname iptables nat chains":
		context => "/files/etc/iptables-save",
		changes => [
			"set table[. = 'nat']/chain[1] PREROUTING",
			"set table[. = 'nat']/chain[1]/policy ACCEPT",
			"set table[. = 'nat']/chain[2] POSTROUTING",
			"set table[. = 'nat']/chain[2]/policy ACCEPT",
			"set table[. = 'nat']/chain[3] OUTPUT",
			"set table[. = 'nat']/chain[3]/policy ACCEPT" ],
		require => Augeas["$hostname iptables tables"];
	}

	if $iptables_default_deny {
		augeas { "$hostname iptables filter chains":
			context => "/files/etc/iptables-save",
			changes => [
				"set table[. = 'filter']/chain[1] INPUT",
				"set table[. = 'filter']/chain[1]/policy DROP",
				"set table[. = 'filter']/chain[2] FORWARD",
				"set table[. = 'filter']/chain[2]/policy ACCEPT",
				"set table[. = 'filter']/chain[3] OUTPUT",
				"set table[. = 'filter']/chain[3]/policy ACCEPT" ],
			require => Augeas["$hostname iptables tables"];
		}
	}
	else {
		augeas { "$hostname iptables filter chains":
			context => "/files/etc/iptables-save",
			changes => [
				"set table[. = 'filter']/chain[1] INPUT",
				"set table[. = 'filter']/chain[1]/policy ACCEPT",
				"set table[. = 'filter']/chain[2] FORWARD",
				"set table[. = 'filter']/chain[2]/policy ACCEPT",
				"set table[. = 'filter']/chain[3] OUTPUT",
				"set table[. = 'filter']/chain[3]/policy ACCEPT" ],
			require => Augeas["$hostname iptables tables"];
		}
	}

}

define iptables_add_exec( $service ) {

	$service_title = "${title}_${service}"

	# We need to ensure this exec always runs after all rules are added for a service
	# This hack is here to ensure we have an exec per service. This service is being added
	# last in a requirement chain
	exec { "exec_$service_title":
		command => "/sbin/iptables-restore /etc/iptables-save",
		user => root
	}
}

# TODO: make this work with other tables, and other chains
define iptables_add_service( $service, $source="", $destination="", $interface="", $jump="ACCEPT" ) {
	$service_title = "${title}_${service}"

	iptables_add_rule{ $service_title: table => "filter", chain => "INPUT", source => $source, destination => $destination, protocol => $iptables_protocols["$service"], destination_port => $iptables_ports["$service"], interface => $interface, jump => $jump }

}

# TODO: Make this work with other tables
define iptables_purge_service( $service ) {
	$service_title = "${title}_${service}"

	iptables_purge_rule{ $service_title: table => "filter" }
}

define iptables_add_rule( $table, $chain, $source="", $destination="", $protocol, $source_port="", $destination_port="", $interface="", $accept_established="false", $jump ) {

	$path_exact = "table[. = \"$table\"]/append[./comment = \"$title\"]"

	# We are basing everything on the comment, so the comment must be added
	# before the entry is set. The match rule for comment must be before the
	# comment though, so we'll explicitly insert it before the comment, then set it.
	augeas { "iptables $title":
		context => "/files/etc/iptables-save",
		onlyif  => "match $path_exact size == 0",
		changes => [
			"set $path_exact/comment \"$title\"",
			"set $path_exact $chain",
			"ins match before $path_exact/comment",
			"set $path_exact/match comment",
			"set $path_exact/protocol $protocol",
			"set $path_exact/jump $jump"
			   ];
	}

	if $source {
		augeas { "iptables $title source":
			context => "/files/etc/iptables-save",
			changes => [ "set $path_exact/source $source" ],
			require => Augeas["iptables $title"];
		}
	}

	if $destination {
		augeas { "iptables $title destination":
			context => "/files/etc/iptables-save",
			changes => [ "set $path_exact/destination $destination" ],
			require => Augeas["iptables $title"];
		}
	}

	if $source_port {
		augeas { "iptables $title source_port":
			context => "/files/etc/iptables-save",
			changes => [ "set $path_exact/sport $source_port" ],
			require => Augeas["iptables $title"];
		}
	}

	if $destination_port {
		augeas { "iptables $title destination_port":
			context => "/files/etc/iptables-save",
			changes => [ "set $path_exact/dport $destination_port" ],
			require => Augeas["iptables $title"];
		}
	}

	if $accept_established == "true" {
		augeas { "iptables $title accept_established":
			context => "/files/etc/iptables-save",
			onlyif  => "match $path_exact/ctstate size == 0",
			changes => [
				"set $path_exact/ctstate \"RELATED,ESTABLISHED\"",
				"ins match before $path_exact/ctstate",
				"set $path_exact/match[2] conntrack"
				   ],
			require => Augeas["iptables $title"];
		}
	}

	if $interface {
		augeas { "iptables $title in_interface":
			context => "/files/etc/iptables-save",
			changes => [ "set $path_exact/in-interface $interface" ],
			require => Augeas["iptables $title"];
		}
	}

}

define iptables_purge_rule( $table ) {

	$path_exact = "table[. = \"$table\"]/append[./comment = \"$title\"]"

	# We are removing the entire node based on the comment field
	augeas { "iptables $title purge":
		context => "/files/etc/iptables-save",
		changes => [ "rm $path_exact" ];
	}
}
