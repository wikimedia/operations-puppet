# bots-cb.pp
import "nagios.pp"
import "nrpe.pp"

class bots-cb::packages {
	# There will eventually be packages for;
	# * CBNG code
	# * CBNG bot
	# * rc
	# * rc2
	# Until then the box requires a lot of manual work,
	# this is a *bad* thing.
	package { [
		"php5-cli", "php5-common", "php5-curl",
		"php5-mysql", "supervisor",
		]: ensure => latest;
	}
}

class bots-cb::monitoring {
	monitor_service {
		"check_wiki_user_last_edit_time":
		description => "ClueBot NG's Last Edit Time",
		check_command => "check_wiki_user_last_edit_time!ClueBot_NG!360!1800",
	}

	monitor_service {
		"check_wiki_user_last_edit_time":
		description => "ClueBot III's Last Edit Time",
		check_command => "check_wiki_user_last_edit_time!ClueBot_III!21600!86400",
	}
}
