# misc/icinga.pp

class icinga::monitor {

	$nagios_mysql_check_pass = $passwords::nagios::mysql::mysql_check_pass

	require nagios::configuration

	# puppet_hosts.cfg must be first
	$puppet_files = [ "${nagios::configuration::icinga_config_dir}/puppet_hosts.cfg",
			  "${nagios::configuration::icinga_config_dir}/puppet_hostgroups.cfg",
			  "${nagios::configuration::icinga_config_dir}/puppet_hostextinfo.cfg",
			  "${nagios::configuration::icinga_config_dir}/puppet_servicegroups.cfg",
			  "${nagios::configuration::icinga_config_dir}/puppet_services.cfg" ]

	$static_files = [
			  "${nagios::configuration::icinga_config_dir}/icinga.cfg",
			  "${nagios::configuration::icinga_config_dir}/cgi.cfg",
			  "${nagios::configuration::icinga_config_dir}/checkcommands.cfg",
#			  "${nagios::configuration::icinga_config_dir}/contactgroups.cfg",
#			  "${nagios::configuration::icinga_config_dir}/contacts.cfg",
			  "${nagios::configuration::icinga_config_dir}/migration.cfg",
			  "${nagios::configuration::icinga_config_dir}/misccommands.cfg",
			  "${nagios::configuration::icinga_config_dir}/resource.cfg",
			  "${nagios::configuration::icinga_config_dir}/timeperiods.cfg",
			  "${nagios::configuration::icinga_config_dir}/htpasswd.users"]

	group { "gammu": gid => "124" }

	systemuser { icinga: name => "icinga", home => "/home/icinga", groups => [ "icinga", "dialout", "gammu" ] }

	# icinga: icinga itself
	# icinga-doc: files for the web-frontend

	package { [ 'icinga', 'icinga-doc' ]:
		ensure => latest;
	}

	# Icinga configuration files

	file { "/etc/icinga/cgi.cfg":
			source => "puppet:///files/icinga/cgi.cfg",
			owner => root,
			group => root,
			mode => 0644;

		"/etc/icinga/icinga.cfg":
			source => "puppet:///files/icinga/icinga.cfg",
			owner => root,
			group => root,
			mode => 0644;

		"/etc/icinga/nsca_payments.cfg":
			source => "puppet:///private/nagios/nsca_payments.cfg",
			owner => root,
			group => root,
			mode => 0644;

		"/etc/icinga/htpasswd.users":
			source => "puppet:///private/nagios/htpasswd.users",
			owner => root,
			group => root,
			mode => 0644;

		"/etc/icinga/checkcommands.cfg":
			content => template("nagios/checkcommands.cfg.erb"),
			owner => root,
			group => root,
			mode => 0644;
# FIXME - lcarr temporarily disable installation of these files to prevent spamming everyone

#		"/etc/icinga/contactgroups.cfg":
#			source => "puppet:///files/nagios/contactgroups.cfg",
#			owner => root,
#			group => root,
#			mode => 0644;

#		"/etc/icinga/contacts.cfg":
#			source => "puppet:///private/nagios/contacts.cfg",
#			owner => root,
#			group => root,
#			mode => 0644;

		"/etc/icinga/migration.cfg":
			source => "puppet:///files/nagios/migration.cfg",
			owner => root,
			group => root,
			mode => 0644;

		"/etc/icinga/misccommands.cfg":
			source => "puppet:///files/nagios/misccommands.cfg",
			owner => root,
			group => root,
			mode => 0644;

		"/etc/icinga/resource.cfg":
			source => "puppet:///files/icinga/resource.cfg",
			owner => root,
			group => root,
			mode => 0644;

		"/etc/icinga/timeperiods.cfg":
			source => "puppet:///files/nagios/timeperiods.cfg",
			owner => root,
			group => root,
			mode => 0644;

		"/etc/icinga/conf.d":
			owner => root,
			group => root,
			mode => 0755,
			ensure => directory;
	}


}
