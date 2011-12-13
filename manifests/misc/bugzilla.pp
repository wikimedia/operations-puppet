# Bugzilla server - http://wikitech.wikimedia.org/view/Bugzilla

class misc::bugzilla::server {

	system_role { "misc::bugzilla::server": description => "Bugzilla server" }

	class {'generic::webserver::php5': ssl => 'true'; }

	apache_site { bugzilla: name => "bugzilla.wikimedia.org" }
}
