# This file is for mobile classes

class mobile::vumi {
	package {
		"python-iso8601":
			ensure => "0.1.4-0";
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
			ensure => "0.4.0~a+git2012040612-0";
		"vumi-wikipedia":
			ensure => "0.1~a+git2012040614-0";
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
		"/etc/vumi/wikipedia_xmpp.yaml":
			owner => "root",
			content => template("mobile/yumi/wikipedia_xmpp.yaml.erb"),
			require => File["/etc/vumi"],
			mode => 0444;
		"/etc/vumi/wikipedia_xmpp_sms.yaml":
			owner => "root",
			content => template("mobile/yumi/wikipedia_xmpp_sms.yaml.erb"),
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
			command => "/usr/local/vumi/rabbitmq.setup.sh"",
			user => "root",
			require => File["/usr/local/vumi/rabbitmq.setup.sh"],
			unless => "/usr/sbin/rabbitmqctl list_user_permissions vumi | grep develop",
	}
}
