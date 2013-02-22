#  Install Mediawiki from git and keep in sync with git trunk
#
#  Uses the mediawiki_singlenode class with minimal alterations or customizations.
class role::mediawiki-install-latest::labs {

	class { "mediawiki_singlenode":
		ensure => latest
	}
}

#  Install Mediawiki from git and then leave it alone.
#
#  Uses the mediawiki_singlenode class with no alterations or customizations.
class role::mediawiki-install::labs {

	class { "mediawiki_singlenode":
		ensure => present
	}
}

# Install Wikidata repo (incl. MediaWiki) from git and keep in sync with git trunk
# This class installs a Wikidata repository. This includes MediaWiki the extensions Wikibase depends on and some other extensions used on the public demo system of the Wikidata project.
#
# Required parameters in wikitech:
# $wikidata_client_ip    - the IP address of a Wikibase client that should be informed about changes in this repo.
#
# Optional parameters in wikitech:
# $wikidata_experimental - true || false, defaults to true, activates experimental features
class role::wikidata-repo-latest::labs {

	class { "wikidata_singlenode":
		install_repo => true,
		install_client => false,
		# get value for experimental features from wikitech
		experimental => $wikidata_experimental,
		# get value for client_ip from wikitech
		client_ip => $wikidata_client_ip,
		# name all repo databases "repo",
		database_name => "repo",
		# get updates from git
		ensure => latest,
		# additional require_once lines can be added here:
		role_requires => [
		'\'wikidata_repo_requires.php\'',
		],
		# additional config lines
		role_config_lines => [
		'$wgSiteNotice = \'<div style="font-size: 90%; background: #FFCC33; padding: 1ex; border: #940 dotted; margin-top: 1ex; margin-bottom: 1ex; ">This is a demo system that shows the current development state of Wikidata.<br /> <strong>This is the bleeding edge.</strong><br /> Expect things to be broken. </div>\'',
		]
	}
}

# Install Wikidata repo (incl. Mediawiki) from git and then leave it alone.
# This class installs a Wikidata repository. This includes MediaWiki the extensions Wikibase depends on and some other extensions used on the public demo system of the Wikidata project.
#
# Required parameters in wikitech:
# $wikidata_client_ip    - the IP address of a Wikibase client that should be informed about changes in this repo.
#
# Optional parameters in wikitech:
# $wikidata_experimental - true || false, defaults to true, activates experimental features
class role::wikidata-repo::labs {

	class { "wikidata_singlenode":
		install_repo => true,
		install_client => false,
		# get value for experimental features from wikitech
		experimental => $wikidata_experimental,
		# get value for client_ip from wikitech
		client_ip => $wikidata_client_ip,
		# name all repo databases "repo",
		database_name => "repo",
		# don't get updates from git
		ensure => present,
		# additional require_once lines can be added here:
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

# Install Wikidata client (incl. MediaWiki) from git and keep in sync with git trunk
# This class installs a Wikibase client. This includes MediaWiki the extensions Wikibase depends on and some other extensions used on the public demo system of the Wikidata project.
#
# Required parameters in wikitech:
# $wikidata_repo_ip             - the IP address of the Wikibase repo this client should get changes from.
# $wikidata_repo_url            - the URL of that same repo
# $wikidata_client_siteGlobalID - A repo can be contacted by different clients that "speak" different languages. The siteGlobalID announces the language of this client. Give the siteGlobalID in a format like "enwiki" for English, "hewiki" for Hebrew, "dewiki" for German etc.
#
# Optional parameters in wikitech:
# $wikidata_experimental        - true || false, defaults to true, activates experimental features
class role::wikidata-client-latest::labs {

	class { "wikidata_singlenode":
		install_client => true,
		install_repo => false,
		# get value for experimental features from wikitech
		experimental => $wikidata_experimental,
		# get value for repo_ip from wikitech
		repo_ip => $wikidata_repo_ip,
		# get value for repo_url from wikitech
		repo_url => $wikidata_repo_url,
		# get value for client's siteGlobalID (like "enwiki") from wikitech
		siteGlobalID => $wikidata_client_siteGlobalID,
		# name all client databases "client",
		database_name => "client",
		# get updates from git
		ensure => latest,
		install_path => "/srv/mediawiki",
		# additional require_once lines can be added here:
		role_requires => [
		'\'wikidata_client_requires.php\'',
		],
		# additional config lines
		role_config_lines => [
		'$wgSiteNotice = \'<div style="font-size: 90%; background: #FFCC33; padding: 1ex; border: #940 dotted; margin-top: 1ex; margin-bottom: 1ex; ">This is a demo system that shows the current development state of Wikidata.<br /> <strong>This is the bleeding edge.</strong><br /> Expect things to be broken. </div>\'',
		]
	}
}

# Install Wikidata client (incl. Mediawiki) from git and then leave it alone.
# This class installs a Wikibase client. This includes MediaWiki the extensions Wikibase depends on and some other extensions used on the public demo system of the Wikidata project.
#
# Required parameters in wikitech:
# $wikidata_repo_ip             - the IP address of the Wikibase repo this client should get changes from.
# $wikidata_repo_url            - the URL of that same repo
# $wikidata_client_siteGlobalID - A repo can be contacted by different clients that "speak" different languages. The siteGlobalID announces the language of this client. Give the siteGlobalID in a format like "enwiki" for English, "hewiki" for Hebrew, "dewiki" for German etc.
#
# Optional parameters in wikitech:
# $wikidata_experimental        - true || false, defaults to true, activates experimental features
class role::wikidata-client::labs {

	class { "wikidata_singlenode":
		install_client => true,
		install_repo => false,
		# get value for experimental features from wikitech
		experimental => $wikidata_experimental,
		# get value for repo_ip from wikitech
		repo_ip => $wikidata_repo_ip,
		# get value for repo_url from wikitech
		repo_url => $wikidata_repo_url,
		# get value for client's siteGlobalID (like "enwiki") from wikitech
		siteGlobalID => $wikidata_client_siteGlobalID,
		# name all client databases "client",
		database_name => "client",
		# don't get updates from git
		ensure => present,
		install_path => "/srv/mediawiki",
		# additional require_once lines can be added here:
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
