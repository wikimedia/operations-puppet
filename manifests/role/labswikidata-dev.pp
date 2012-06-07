#include "labsmysql.pp"
#include "webserver.pp"
#include "generic-definitions.pp"

class role::labswikidata-dev {

    require "apachesetup",
		"role::labs-mysql-server",
		"webserver::php5-mysql",
		"webserver::php5"

	git::clone { "w":
		directory => "/var/www/wikidata-dev-repo",
		branch => "Wikidata",
		origin => "https://gerrit.wikimedia.org/r/p/mediawiki/core.git";
	}
	git::clone { "w":
		directory => "/var/www/wikidata-dev-client",
		branch => "Wikidata",
		origin => "https://gerrit.wikimedia.org/r/p/mediawiki/core.git";
	}
	git::clone { "WikibaseLib":
		directory => "/var/www/wikidata-dev-client/w/extensions",
		branch => "master",
		origin => "https://gerrit.wikimedia.org/r/p/mediawiki/extensions/WikibaseLib.git";
	}
	git::clone { "wikibase":
		directory => "/var/www/wikidata-dev-client/w/extensions",
		branch => "master",
		origin => "https://gerrit.wikimedia.org/r/p/mediawiki/extensions/WikidataRepo.git";
	}
	git::clone { "WikibaseLib":
		directory => "/var/www/wikidata-dev-repo/w/extensions",
		branch => "master",
		origin => "https://gerrit.wikimedia.org/r/p/mediawiki/extensions/WikibaseLib.git";
	}
	git::clone { "wikibase":
		directory => "/var/www/wikidata-dev-repo/w/extensions",
		branch => "master",
		origin => "https://gerrit.wikimedia.org/r/p/mediawiki/extensions/WikidataRepo.git";
	}
}
