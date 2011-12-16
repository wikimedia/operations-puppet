# this file is for: outreach / contacts / (civi)CRM related things
# (constituency relationship management)

# https://contacts.wikimedia.org | http://en.wikipedia.org/wiki/CiviCRM
class misc::outreach::civicrm {
	system_role { "misc::outreach::civicrm": description => "CiviCRM server" }

	class {'generic::webserver::php5': ssl => 'true'; }

	apache_site { contacts: name => "contacts.wikimedia.org" }

	systemuser { civimail: name => "civimail", home => "/home/civimail", groups => [ "civimail" ] }
}

# https://outreachcivi.wikimedia.org/
class misc::outreach::outreachcivi {
	system_role { "misc::outreach::outreachcivi": description => "outreachcivi.wikimedia.org" }

	class {'generic::webserver::php5': ssl => 'true'; }

	apache_site { outreachcivi: name => "outreachcivi.wikimedia.org" }
}
