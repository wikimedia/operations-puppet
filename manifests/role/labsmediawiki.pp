#  Install Mediawiki from git and keep in sync with git trunk
#
#  Uses the mediawiki::singlenode class with minimal alterations or customizations.
class role::mediawiki-install-latest::labs {

	class { "mediawiki::singlenode":
		ensure => latest
	}
}

#  Install Mediawiki from git and then leave it alone.
#
#  Uses the mediawiki::singlenode class with no alterations or customizations.
class role::mediawiki-install::labs {

	class { "mediawiki::singlenode":
		ensure => present
	}
}

#  Install Wikidata repo (incl. MediaWiki) from git and keep in sync with git trunk
class role::wikidata-repo-latest::labs {

	class { "wikidata::singlenode":
		install_repo => true,
		install_client => false,
		experimental => $wikidata_experimental,
		client_ip => $wikidata_client_ip,
		database_name => "repo",
		ensure => latest,
		# all require_once lines here:
		role_requires => [
		'\'wikidata_repo_requires.php\'',
		],
		# additional config lines
		role_config_lines => [
		'$wgSiteNotice = \'<div style="font-size: 90%; background: #FFCC33; padding: 1ex; border: #940 dotted; margin-top: 1ex; margin-bottom: 1ex; ">This is a demo system that shows the current development state of Wikidata.<br /> <strong>This is the bleeding edge.</strong><br /> Expect things to be broken. </div>\'',
		]
	}
}

#  Install Wikidata repo (incl. Mediawiki) from git and then leave it alone.
class role::wikidata-repo::labs {

	class { "wikidata::singlenode":
		install_repo => true,
		install_client => false,
		experimental => $wikidata_experimental,
		client_ip => $wikidata_client_ip,
		database_name => "repo",
		ensure => present,
		# all require_once lines here:
		role_requires => [
		'\'wikidata_repo_requires.php\'',
		],
		# additional config lines
		role_config_lines => [
		'// DismissableSiteNotice',
		'$wgSiteNotice = \'<div style="font-size: 90%; background: #FFCC33; padding: 1ex; border: #940 dotted; margin-top: 1ex; margin-bottom: 1ex; ">This is a demo system that shows the current development state of Wikidata. It is going to evolve over the next few weeks. All data here can be deleted any time.<br>If you find bugs please report them in [https://bugzilla.wikimedia.org/enter_bug.cgi?product=MediaWiki%20extensions Bugzilla] for the Wikidata Client or Repo component. [https://meta.wikimedia.org/wiki/Wikidata/Development/Howto_Bugreport Here is how to submit a bug.] If you would like to discuss something or give input please use the [https://lists.wikimedia.org/mailman/listinfo/wikidata-l mailing list]. Thank you!</div>\'',
		]
	}
}

#  Install Wikidata client (incl. MediaWiki) from git and keep in sync with git trunk
class role::wikidata-client-latest::labs {

	class { "wikidata::singlenode":
		install_client => true,
		install_repo => false,
		experimental => $wikidata_experimental,
		repo_ip => $wikidata_repo_ip,
		repo_url => $wikidata_repo_url,
		siteGlobalID => $wikidata_client_siteGlobalID,
		database_name => "client",
		ensure => latest,
		install_path => "/srv/mediawiki",
		# all require_once lines here:
		role_requires => [
		'\'wikidata_client_requires.php\'',
		],
		# additional config lines
		role_config_lines => [
		'$wgSiteNotice = \'<div style="font-size: 90%; background: #FFCC33; padding: 1ex; border: #940 dotted; margin-top: 1ex; margin-bottom: 1ex; ">This is a demo system that shows the current development state of Wikidata.<br /> <strong>This is the bleeding edge.</strong><br /> Expect things to be broken. </div>\'',
		]
	}
}

#  Install Wikidata client (incl. Mediawiki) from git and then leave it alone.
class role::wikidata-client::labs {

	class { "wikidata::singlenode":
		install_client => true,
		install_repo => false,
		experimental => $wikidata_experimental,
		repo_ip => $wikidata_repo_ip,
		repo_url => $wikidata_repo_url,
		siteGlobalID => $wikidata_client_siteGlobalID,
		database_name => "client",
		ensure => present,
		install_path => "/srv/mediawiki",
		# all require_once lines here:
		role_requires => [
		'\'wikidata_client_requires.php\'',
		],
		# additional config lines
		role_config_lines => [
		'// DismissableSiteNotice',
		'$wgSiteNotice = \'<div style="font-size: 90%; background: #FFCC33; padding: 1ex; border: #940 dotted; margin-top: 1ex; margin-bottom: 1ex; ">This is a demo system that shows the current development state of Wikidata. It is going to evolve over the next few weeks. All data here can be deleted any time.<br>If you find bugs please report them in [https://bugzilla.wikimedia.org/enter_bug.cgi?product=MediaWiki%20extensions Bugzilla] for the Wikidata Client or Repo component. [https://meta.wikimedia.org/wiki/Wikidata/Development/Howto_Bugreport Here is how to submit a bug.] If you would like to discuss something or give input please use the [https://lists.wikimedia.org/mailman/listinfo/wikidata-l mailing list]. Thank you!</div>\'',
		]
	}
}
