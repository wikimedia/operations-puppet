# This file is for mobile classes

class mobile::vumi {

	include passwords::mobile::vumi
	$testvumi_pw = $passwords::mobile::vumi::wikipedia_xmpp_sms_out
	$vumi_pw = $passwords::mobile::vumi::wikipedia_xmpp
	$tata_sms_incoming_pw = $passwords::mobile::vumi::tata_sms_incoming_pw
	$tata_sms_outgoing_pw = $passwords::mobile::vumi::tata_sms_outgoing_pw
	$tata_ussd_pw = $passwords::mobile::vumi::tata_ussd_pw
	$tata_hyd_ussd_pw = $passwords::mobile::vumi::tata_hyd_ussd_pw
	$testvumi_pw = $passwords::mobile::vumi::testvumi_pw


	package {
		"python-iso8601":
			ensure => "0.1.4-1";
		"python-redis":
			ensure => "2.4.5-1";
		"python-smpp":
			ensure => "0.1-0";
		"python-ssmi":
			ensure => "0.0.4-0";
		"redis-server":
			ensure => "latest";
		"python-txamqp":
			ensure => "0.6.1-0";
		"vumi":
			ensure => "0.5.0~a+99-0";
		"vumi-wikipedia":
			ensure => "0.1~a+9-0";
		"python-twisted":
			ensure => "latest";
		"python-tz":
			ensure => "latest";
		"python-wokkel":
			ensure => "0.6.3-1";
		"rabbitmq-server":
			ensure => "latest";
	}

	file {
		"/etc/vumi":
			ensure => "directory",
			owner => "root";
		"/var/log/vumi":
			ensure => "directory",
			owner => "root";
		"/etc/vumi/wikipedia.yaml":
			owner => "root",
			source => "puppet:///files/mobile/vumi/wikipedia.yaml",
			require => File["/etc/vumi"],
			mode => 0444;
		"/etc/vumi/tata_ussd_hyd.yaml":
			owner => "root",
			content => template("mobile/vumi/tata_ussd_hyd.yaml.erb"),
			require => File["/etc/vumi"],
			mode => 0444;
		"/etc/vumi/tata_sms_outgoing.yaml":
			owner => "root",
			content => template("mobile/vumi/tata_sms_outgoing.yaml.erb"),
			require => File["/etc/vumi"],
			mode => 0444;
			"/etc/vumi/tata_ussd_delhi.yaml":
			owner => "root",
			content => template("mobile/vumi/tata_ussd_delhi.yaml.erb"),
			require => File["/etc/vumi"],
			mode => 0444;
			"/etc/vumi/tata_sms_incoming.yaml":
			owner => "root",
			content => template("mobile/vumi/tata_sms_incoming.yaml.erb"),
			require => File["/etc/vumi"],
			mode => 0444;
			"/etc/vumi/supervisord.wikipedia.conf":
			owner => "root",
			source => "puppet:///files/mobile/vumi/supervisord.wikipedia.conf",
			require => File["/etc/vumi"],
			mode => 0444;
		"/etc/vumi/wikipedia_xmpp.yaml":
			owner => "root",
			content => template("mobile/vumi/wikipedia_xmpp.yaml.erb"),
			require => File["/etc/vumi"],
			mode => 0444;
		"/etc/vumi/wikipedia_xmpp_sms.yaml":
			owner => "root",
			content => template("mobile/vumi/wikipedia_xmpp_sms.yaml.erb"),
			require => File["/etc/vumi"],
			mode => 0444;
		"/usr/local/vumi":
			owner => "root",
			ensure => "directory";
		"/usr/local/vumi/rabbitmq.setup.sh":
			owner => "root",
			mode => 0555,
			require => File["/usr/local/vumi"],
			source => "puppet:///files/mobile/vumi/rabbitmq.setup.sh";
		"/etc/vumi/supervisord.wikipedia.conf":
			owner => "root",
			mode => 0555,
			require => File["/etc/vumi"],
			source => "puppet:///files/mobile/vumi/supervisord.wikipedia.conf";
	}

	exec {
		"Set permissions for rabbitmq user":
			command => "/usr/local/vumi/rabbitmq.setup.sh",
			user => "root",
			require => File["/usr/local/vumi/rabbitmq.setup.sh"],
			unless => "/usr/sbin/rabbitmqctl list_user_permissions vumi | grep develop",
	}
}
