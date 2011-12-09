# Wikimania special sites

# OCS (Open Conference Systems) - http://pkp.sfu.ca/?q=ocs
class misc::ocs::wikimania2009 {
	system_role { "misc::ocs::wikimania2009": description => "Wikimania 2009 OCS server" }

	class {'generic::webserver::php5': ssl => 'true'; }

	apache_site { ocs_wikimania2009: name => "ocs.wikimania2009.wikimedia.org" }
}

# wm09schols
class misc::schols::wm09 {
	system_role { "misc::schols:wm09": description => "wm09schols server" }

	class {'generic::webserver::php5': ssl => 'true'; }

	apache_site { wm09schols: name => "wm09schols.wikimedia.org" }
}

# wm10schols
class misc::schols::wm10 {
	system_role { "misc::schols:wm10": description => "wm10schols server" }

	class {'generic::webserver::php5': ssl => 'true'; }

	apache_site { wm10schols: name => "wm10schols.wikimedia.org" }
}

# wm10reg
class misc::reg::wm10 {
	system_role { "misc::reg:wm10": description => "wm10reg server" }

	class {'generic::webserver::php5': ssl => 'true'; }

	apache_site { wm10reg: name => "wm10reg.wikimedia.org" }
}
