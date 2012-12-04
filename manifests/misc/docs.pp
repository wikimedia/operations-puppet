class misc::docsite {

	class {'webserver::php5': ssl => 'true'; }

	file {
		"/etc/apache2/sites-available/doc.mediawiki.org":
		path => "/etc/apache2/sites-available/doc.mediawiki.org",
		mode => 0444,
		owner => root,
		group => root,
		source => "puppet:///files/apache/sites/doc.mediawiki.org";
	}

	apache_site { docs: name => "doc.mediawiki.org" }
}
