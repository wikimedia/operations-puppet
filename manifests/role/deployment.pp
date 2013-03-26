# vim: sw=2 ts=2 et
class role::deployment::salt_masters::common($deployment_servers) {
  $deploy_server_pmtpa = $deployment_servers["pmtpa"]
  $deploy_server_eqiad = $deployment_servers["eqiad"]
  $deployment_repo_urls = {
    "pmtpa" => {
      "private" => "http://${deploy_server_pmtpa}/mediawiki/private",
      "common" => "http://${deploy_server_pmtpa}/mediawiki/common",
      "slot0" => "http://${deploy_server_pmtpa}/mediawiki/slot0",
      "slot1" => "http://${deploy_server_pmtpa}/mediawiki/slot1",
      "beta0" => "http://${deploy_server_pmtpa}/mediawiki/beta0",
      "l10n-slot0" => "http://${deploy_server_pmtpa}/mediawiki/l10n-slot0",
      "l10n-slot1" => "http://${deploy_server_pmtpa}/mediawiki/l10n-slot1",
      "l10n-beta0" => "http://${deploy_server_pmtpa}/mediawiki/l10n-beta0",
      # parsoid is currently deployed from eqiad only
      "parsoid/Parsoid" => "http://${deploy_server_eqiad}/parsoid/Parsoid",
      "parsoid/config" => "http://${deploy_server_eqiad}/parsoid/config",
      # eventlogging is currently deployed from eqiad only
      "eventlogging/EventLogging" => "http://${deploy_server_eqiad}/eventlogging/EventLogging",
    },
    "eqiad" => {
      "private" => "http://${deploy_server_eqiad}/mediawiki/private",
      "common" => "http://${deploy_server_eqiad}/mediawiki/common",
      "slot0" => "http://${deploy_server_eqiad}/mediawiki/slot0",
      "slot1" => "http://${deploy_server_eqiad}/mediawiki/slot1",
      "beta0" => "http://${deploy_server_eqiad}/mediawiki/beta0",
      "l10n-slot0" => "http://${deploy_server_eqiad}/mediawiki/l10n-slot0",
      "l10n-slot1" => "http://${deploy_server_eqiad}/mediawiki/l10n-slot1",
      "l10n-beta0" => "http://${deploy_server_eqiad}/mediawiki/l10n-beta0",
      "parsoid/Parsoid" => "http://${deploy_server_eqiad}/parsoid/Parsoid",
      "parsoid/config" => "http://${deploy_server_eqiad}/parsoid/config",
      "eventlogging/EventLogging" => "http://${deploy_server_eqiad}/eventlogging/EventLogging",
    },
  }
  # Sed the .gitmodules file for the repo according to the following rules
  # TODO: rename this to something more specific
  $deployment_repo_regex = {
    "common" => {},
    "private" => {},
    "slot0" => {
      "https://gerrit.wikimedia.org/r/p/mediawiki" => "__REPO_URL__/.git/modules",
      ".git" => "",
    },
    "slot1" => {
      "https://gerrit.wikimedia.org/r/p/mediawiki" => "__REPO_URL__/.git/modules",
      ".git" => "",
    },
    "beta0" => {
      "https://gerrit.wikimedia.org/r/p/mediawiki" => "__REPO_URL__/.git/modules",
      ".git" => "",
    },
    "l10n-slot0" => {},
    "l10n-slot1" => {},
    "l10n-beta0" => {},
    "parsoid/Parsoid" => {},
    "parsoid/config" => {},
    "eventlogging/EventLogging" => {},
  }
  # Call these salt modules after checkout of parent repo and submodules
  # TODO: turn this into a hash so that modules can specify args too
  $deployment_repo_checkout_module_calls = {
    "private" => [],
    "common" => [],
    "slot0" => [],
    "slot1" => [],
    "beta0" => [],
    "l10n-slot0" => [],
    "l10n-slot1" => [],
    "l10n-beta0" => [],
    "parsoid/Parsoid" => ["parsoid.config_symlink","parsoid.restart_parsoid"],
    "parsoid/config" => ["parsoid.restart_parsoid"],
    "eventlogging/EventLogging" => [],
  }
  # Should this repo also do a submodule update --init?
  $deployment_repo_checkout_submodules = {
    "private" => "False",
    "common" => "False",
    "slot0" => "True",
    "slot1" => "True",
    "beta0" => "True",
    "l10n-slot0" => "False",
    "l10n-slot1" => "False",
    "l10n-beta0" => "False",
    "parsoid/Parsoid" => "False",
    "parsoid/config" => "False",
    "eventlogging/EventLogging" => "False",
  }
  $deployment_repo_locations = {
    "private" => "/srv/deployment/mediawiki/private",
    "common" => "/srv/deployment/mediawiki/common",
    "slot0" => "/srv/deployment/mediawiki/slot0",
    "slot1" => "/srv/deployment/mediawiki/slot1",
    "beta0" => "/srv/deployment/mediawiki/beta0",
    "l10n-slot0" => "/srv/deployment/mediawiki/l10n-slot0",
    "l10n-slot1" => "/srv/deployment/mediawiki/l10n-slot1",
    "l10n-beta0" => "/srv/deployment/mediawiki/l10n-beta0",
    "parsoid/Parsoid" => "/srv/deployment/parsoid/Parsoid",
    "parsoid/config" => "/srv/deployment/parsoid/config",
    "eventlogging/EventLogging" => "/srv/deployment/eventlogging/EventLogging",
  }
  # ensure dependent repos are fetched and checked out with this repo
  # repos fetched/checkedout in order
  $deployment_repo_dependencies = {
    "slot0" => ["l10n-slot0"],
    "slot1" => ["l10n-slot1"],
    "beta0" => ["l10n-beta0"],
  }
}

class role::deployment::salt_masters::production {
  $mediawiki_regex = "^(srv|mw|snapshot|tmh)|(searchidx2|searchidx1001).*.(eqiad|pmtpa).wmnet$|^(hume|spence|fenari).wikimedia.org$"
  $parsoid_regex = "^(wtp1|mexia|tola|lardner|kuo|celsus|constable|wtp1001|wtp1002|wtp1003|wtp1004|cerium|titanium)\..*"
  $eventlogging_regex = "^(vanadium).eqiad.wmnet$"
  $deployment_servers = {
    "pmtpa" => "tin.eqiad.wmnet",
    "eqiad" => "tin.eqiad.wmnet",
  }
  class { "role::deployment::salt_masters::common":
    deployment_servers => $deployment_servers,
  }
  class { "deployment::salt_master":
    deployment_servers => $deployment_servers,
    deployment_repo_urls => $role::deployment::salt_masters::common::deployment_repo_urls,
    deployment_repo_regex => $role::deployment::salt_masters::common::deployment_repo_regex,
    deployment_repo_checkout_module_calls => $role::deployment::salt_masters::common::deployment_repo_checkout_module_calls,
    deployment_repo_checkout_submodules => $role::deployment::salt_masters::common::deployment_repo_checkout_submodules,
    deployment_repo_locations => $role::deployment::salt_masters::common::deployment_repo_locations,
    deployment_repo_dependencies => $role::deployment::salt_masters::common::deployment_repo_dependencies,
    deployment_minion_regex => {
      "private"  => $mediawiki_regex,
      "common"  => $mediawiki_regex,
      "slot0"   => $mediawiki_regex,
      "slot1"   => $mediawiki_regex,
      "beta0" => '^$',  # no master branch in production
      "l10n-slot0"   => $mediawiki_regex,
      "l10n-slot1"   => $mediawiki_regex,
      "l10n-beta0"   => '^$',  # no master branch in production
      "parsoid/Parsoid" => $parsoid_regex,
      "parsoid/config" => $parsoid_regex,
      "eventlogging/EventLogging" => $eventlogging_regex,
    },
    deployment_deploy_redis => {
      "host" => "tin.eqiad.wmnet",
      "port" => 6379,
      "db" => "0",
    },
  }
}

class role::deployment::salt_masters::labs {
  $mediawiki_regex = "^(i-000004ff|i-000004cc|i-0000031b|i-0000031a).pmtpa.wmflabs"
  $parsoid_regex = "^$"
  $eventlogging_regex = "^$"
  $deployment_servers = {
    "pmtpa" => "i-00000390.pmtpa.wmflabs",
    # no eqiad zone, yet
    "eqiad" => "i-00000390.pmtpa.wmflabs",
  }
  class { "role::deployment::salt_masters::common":
    deployment_servers => $deployment_servers,
  }
  class { "deployment::salt_master":
    deployment_servers => $deployment_servers,
    deployment_repo_urls => $role::deployment::salt_masters::common::deployment_repo_urls,
    deployment_repo_regex => $role::deployment::salt_masters::common::deployment_repo_regex,
    deployment_repo_checkout_module_calls => $role::deployment::salt_masters::common::deployment_repo_checkout_module_calls,
    deployment_repo_checkout_submodules => $role::deployment::salt_masters::common::deployment_repo_checkout_submodules,
    deployment_repo_locations => $role::deployment::salt_masters::common::deployment_repo_locations,
    deployment_repo_dependencies => $role::deployment::salt_masters::common::deployment_repo_dependencies,
    deployment_minion_regex => {
      "private"  => $mediawiki_regex,
      "common"  => $mediawiki_regex,
      "slot0"   => $mediawiki_regex,
      "slot1"   => $mediawiki_regex,
      "beta0"   => $mediawiki_regex,
      "l10n-slot0"   => $mediawiki_regex,
      "l10n-slot1"   => $mediawiki_regex,
      "l10n-beta0"   => $mediawiki_regex,
      "parsoid/Parsoid" => $parsoid_regex,
      "parsoid/config" => $parsoid_regex,
      "eventlogging/EventLogging" => $eventlogging_regex,
    },
    deployment_deploy_redis => {
      "host" => "i-00000390.pmtpa.wmflabs",
      "port" => 6379,
      "db" => "0",
    },
  }
}

class role::deployment::deployment_servers::common {
  # Can't include this while scap is present on tin:
  # include misc::deployment::scripts

  class { "deployment::deployment_server": }

  deployment::deployment_repo_sync_hook_link { "private": target => "shared.py" }
  deployment::deployment_repo_sync_hook_link { "common": target => "shared.py" }
  deployment::deployment_repo_sync_hook_link { "slot0": target => "shared.py" }
  deployment::deployment_repo_sync_hook_link { "slot1": target => "shared.py" }
  deployment::deployment_repo_sync_hook_link { "beta0": target => "shared.py" }
  deployment::deployment_repo_sync_hook_link { "l10n-slot0": target => "depends.py" }
  deployment::deployment_repo_sync_hook_link { "l10n-slot1": target => "depends.py" }
  deployment::deployment_repo_sync_hook_link { "l10n-beta0": target => "depends.py" }
  deployment::deployment_repo_dependencies_link { "l10n-slot0": target => "l10n" }
  deployment::deployment_repo_dependencies_link { "l10n-slot1": target => "l10n" }
  deployment::deployment_repo_dependencies_link { "l10n-beta0": target => "l10n" }
  deployment::deployment_repo_sync_hook_link { "parsoid/Parsoid": target => "shared.py" }
  deployment::deployment_repo_sync_hook_link { "parsoid/config": target => "shared.py" }
  deployment::deployment_repo_sync_hook_link { "eventlogging/EventLogging": target => "shared.py" }

  class { "apache": }
  class { "apache::mod::dav": }
  class { "apache::mod::dav_fs": }

  class { "applicationserver::packages": }

  apache::vhost { "default":
    priority		=> 000,
    port		=> 80,
    docroot		=> "/var/www",
    ensure		=> absent,
    configure_firewall 	=> false,
  }
}

class role::deployment::deployment_servers::production {
  include role::deployment::deployment_servers::common

  apache::vhost { "tin.eqiad.wmnet":
    priority		=> 10,
    vhost_name		=> "10.64.0.196",
    port		=> 80,
    docroot		=> "/srv/deployment",
    docroot_dir_allows  => ["10.0.0.0/16","10.64.0.0/16","208.80.152.0/22"],
    serveradmin		=> "noc@wikimedia.org",
    configure_firewall 	=> false,
  }
  class { "redis":
    dir => "/srv/redis",
    maxmemory => "500Mb",
    monitor => "true",
  }
  sudo_group { "wikidev_deployment_server":
    privileges => [
      "ALL = (root) NOPASSWD: /usr/bin/salt-call --out json pillar.data",
      "ALL = (root) NOPASSWD: /usr/bin/salt-call publish.runner deploy.fetch *",
      "ALL = (root) NOPASSWD: /usr/bin/salt-call publish.runner deploy.checkout *",
    ],
    group => "wikidev",
  }
}

class role::deployment::deployment_servers::labs {
  include role::deployment::deployment_servers::common

  apache::vhost { "i-00000390.pmtpa.wmflabs":
    priority		=> 10,
    vhost_name		=> "10.4.0.58",
    port		=> 80,
    docroot		=> "/srv/deployment",
    docroot_dir_allows  => ["10.4.0.0/16"],
    serveradmin		=> "noc@wikimedia.org",
    configure_firewall 	=> false,
  }
  class { "redis":
    dir => "/srv/redis",
    maxmemory => "500Mb",
    monitor => "false",
  }
  sudo_group { "project_deployment_prep_deployment_server":
    privileges => [
      "ALL = (root) NOPASSWD: /usr/bin/salt-call --out json pillar.data",
      "ALL = (root) NOPASSWD: /usr/bin/salt-call publish.runner deploy.fetch *",
      "ALL = (root) NOPASSWD: /usr/bin/salt-call publish.runner deploy.checkout *",
    ],
    group => "project-deployment-prep",
  }
}
