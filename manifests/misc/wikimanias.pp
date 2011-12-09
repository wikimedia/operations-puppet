# Wikimania special sites

# ocs - 2009 - OCS (Open Conference Systems) - http://pkp.sfu.ca/?q=ocs
class misc::wikimania::ocs_2009 {
	system_role { "misc::wikimania::ocs_2009": description => "ocs.wikimania2009.wikimedia.org" }

	class {'generic::webserver::php5': ssl => 'true'; }

	apache_site { ocs_wikimania2009: name => "ocs.wikimania2009.wikimedia.org" }
}

# reg - 2010
class misc::wikimania::reg_2010 {
	system_role { "misc::wikimania::reg_2010": description => "wm10reg.wikimedia.org" }

	class {'generic::webserver::php5': ssl => 'true'; }

	apache_site { wm10reg: name => "wm10reg.wikimedia.org" }
}

# schols - 2009
class misc::wikimania::schols_2009 {
	system_role { "misc::wikimania::schols_2009": description => "wm09schols.wikimedia.org" }

	class {'generic::webserver::php5': ssl => 'true'; }

	apache_site { wm09schols: name => "wm09schols.wikimedia.org" }
}

# schols - 2010
class misc::wikimania::schols_2010 {
	system_role { "misc::wikimania::schols_2010": description => "wm10schols.wikimedia.org" }

	class {'generic::webserver::php5': ssl => 'true'; }

	apache_site { wm10schols: name => "wm10schols.wikimedia.org" }
}
