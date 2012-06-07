class role::labswikidata-dev {

		require	"apachesetup",
		"role::labs-mysql-server",
		"webserver::php5-mysql",
		"webserver::php5"

  package { [ "imagemagick", "php-apc",  ] :
    ensure => latest
  }

  $repo = "wikidata-dev-repo.wikimedia.de"
  $client = "wikidata-dev-client.wikimedia.de"

  class { "memcached":
    memcached_ip => "127.0.0.1" }

  file {
    "/etc/apache2/sites-available/wiki":
      mode => 644,
      owner => root,
      group => root,
      content => template("apache/sites/wikidata-dev"),
      ensure => present
  }

  file { "/var/www/#{$repo}":
    require => File["/var/www/"],
    ensure => "link",
    target => "/srv/#{$repo}"
  }
  file { "/var/www/#{$client}":
    require => File["/var/www/"],
    ensure => "link",
    target => "/srv/#{$client}"
  }

  if $labs_mediawiki_hostname {
    $mwserver = "http://$labs_mediawiki_hostname"
  } else {
    $mwserver = "http://$hostname.pmtpa.wmflabs"
  }

  exec { "wikidata_client_setup":
    creates => "/srv/#{$client}/LocalSettings.php",
    command => "/usr/bin/php /srv/#{$client}/maintenance/install.php testwiki admin --dbname testwiki --dbuser root --pass adminpassword --server $mwserver --scriptpath /srv/#{$client} --confpath /srv/#{$client}",
  }

  exec { "wikidata_repo_setup":
    creates => "/srv/#{$repo}/LocalSettings.php",
    command => "/usr/bin/php /srv/#{$repo}/maintenance/install.php testwiki admin --dbname testwiki --dbuser root --pass adminpassword --server $mwserver --scriptpath /srv/#{$repo} --confpath /srv/#{$repo}",
  }

  apache_site { controller: name => "wiki" }
  apache_site { 000_default: name => "000-default", ensure => absent }

  exec { "apache_restart":
    require => apache_site["controller", "000_default"],
    command => "/usr/sbin/service apache2 restart"
  }

  file { "/srv/#{$client}/LocalSettings.php":
    require => exec["wikidata_client_setup"],
    content => template("mediawiki/wikidata-client-localsettings"),
    ensure => present,
  }

  file { "/srv/#{$repo}/LocalSettings.php":
    require => exec["wikidata_repo_setup"],
    content => template("mediawiki/wikidata-repo-localsettings"),
    ensure => present,
  }

	git::clone { "w":
		directory => "/srv/#{$repo}",
		branch => "Wikidata",
		origin => "https://gerrit.wikimedia.org/r/p/mediawiki/core.git"
	}
	git::clone { "w":
		directory => "/srv/#{$client}",
		branch => "Wikidata",
		origin => "https://gerrit.wikimedia.org/r/p/mediawiki/core.git"
	}
	git::clone { "WikibaseLib":
		directory => "/srv/#{$repo}/w/extensions",
		branch => "master",
		origin => "https://gerrit.wikimedia.org/r/p/mediawiki/extensions/WikibaseLib.git"
	}
	git::clone { "wikibase":
		directory => "/srv/#{$client}/w/extensions",
		branch => "master",
		origin => "https://gerrit.wikimedia.org/r/p/mediawiki/extensions/WikidataRepo.git"
	}
	git::clone { "WikibaseLib":
		directory => "/srv/#{$repo}/w/extensions",
		branch => "master",
		origin => "https://gerrit.wikimedia.org/r/p/mediawiki/extensions/WikibaseLib.git"
	}
	git::clone { "wikibase":
		directory => "/srv/#{$client}/w/extensions",
		branch => "master",
		origin => "https://gerrit.wikimedia.org/r/p/mediawiki/extensions/WikidataRepo.git"
	}
}
