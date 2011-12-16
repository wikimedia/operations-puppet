# Wikimania special sites

# OCS (Open Conference Systems) - http://pkp.sfu.ca/?q=ocs
class misc::ocs::wikimania2009 {
	system_role { "misc::ocs::wikimania2009": description => "Wikimania 2009 OCS server" }

	class {'generic::webserver::php5': ssl => 'true'; }

	apache_site { contacts: name => "ocs.wikimania2009.wikimedia.org" }
}
