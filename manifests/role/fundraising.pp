@monitor_group { "fundraising_eqiad": description => "fundraising eqiad" }
@monitor_group { "fundraising_pmtpa": description => "fundraising pmtpa" }

class role::fundraising::civicrm {
	# variables used in fundraising exim template
	$exim_signs_dkim = "true"
	$exim_bounce_collector = "true"

	$cluster = "fundraising"
	$nagios_group = "${cluster}_${::site}"

	#install_certificate{ "star.wikimedia.org": }

	sudo::user { [ "khorn" ]: privileges => ['ALL = NOPASSWD: ALL'] }

	$gid = 500
	include standard-noexim,
		#accounts::mhernandez, # migrated to lutetium
		#accounts::zexley, # migrated to lutetium
		#accounts::pcoombe, # migrated to lutetium
		admins::fr-tech,
		admins::roots,
		backup::client,
		misc::fundraising,
		misc::fundraising::backup::backupmover_user,
		misc::fundraising::mail,
		nrpe
	monitor_service { "smtp": description => "Exim SMTP", check_command => "check_smtp" }
	monitor_service { "http": description => "HTTP", check_command => "check_http" }
}
