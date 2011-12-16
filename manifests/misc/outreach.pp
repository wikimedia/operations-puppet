# this file is for: outreach / contacts / (civi)CRM related things
# (constituency relationship management)

# https://contacts.wikimedia.org | http://en.wikipedia.org/wiki/CiviCRM
class misc::outreach::civicrm {
	system_role { "misc::civicrm": description => "CiviCRM server" }

	class {'generic::webserver::php5': ssl => 'true'; }

	apache_site { contacts: name => "contacts.wikimedia.org" }

	systemuser { civimail: name => "civimail", home => "/home/civimail", groups => [ "civimail" ] }
}
