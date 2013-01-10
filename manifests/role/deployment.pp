# vim: sw=2 ts=2 et
class role::deployment::salt_masters::common($deployment_servers) {
  $deploy_server_pmtpa = $deployment_servers["pmtpa"]
  $deploy_server_eqiad = $deployment_servers["eqiad"]
  $deployment_repo_urls = {
    "pmtpa" => {
      "common" => "http://${deploy_server_pmtpa}//common",
      "slot0" => "http://${deploy_server_pmtpa}/mediawiki/slot0",
      "slot1" => "http://${deploy_server_pmtpa}/mediawiki/slot1",
      "l10n-slot0" => "http://${deploy_server_pmtpa}/mediawiki/l10n-slot0",
      "l10n-slot1" => "http://${deploy_server_pmtpa}/mediawiki/l10n-slot1",
      # parsoid is currently deployed from eqiad only
      "parsoid/parsoid" => "http://${deploy_server_eqiad}/parsoid/parsoid",
      "parsoid/config" => "http://${deploy_server_eqiad}/parsoid/config",
    },
    "eqiad" => {
      "common" => "http://${deploy_server_eqiad}/mediawiki/common",
      "slot0" => "http://${deploy_server_eqiad}/mediawiki/slot0",
      "slot1" => "http://${deploy_server_eqiad}/mediawiki/slot1",
      "l10n-slot0" => "http://${deploy_server_eqiad}/mediawiki/l10n-slot0",
      "l10n-slot1" => "http://${deploy_server_eqiad}/mediawiki/l10n-slot1",
      "parsoid/Parsoid" => "http://${deploy_server_eqiad}/parsoid/Parsoid",
      "parsoid/config" => "http://${deploy_server_eqiad}/parsoid/config",
    },
  }
  # Sed the .gitmodules file for the repo according to the following rules
  # TODO: rename this to something more specific
  $deployment_repo_regex = {
    "common" => {},
    "slot0" => {
      "https://gerrit.wikimedia.org/r/p/mediawiki" => "__REPO_URL__/.git/modules",
      ".git" => "",
    },
    "slot1" => {
      "https://gerrit.wikimedia.org/r/p/mediawiki" => "__REPO_URL__/.git/modules",
      ".git" => "",
    },
    "l10n-slot0" => {},
    "l10n-slot1" => {},
    "parsoid/Parsoid" => {},
    "parsoid/config" => {},
  }
  # Call these salt modules after checkout of parent repo and submodules
  # TODO: turn this into a hash so that modules can specify args too
  $deployment_repo_checkout_module_calls = {
    "common" => [],
    "slot0" => [],
    "slot1" => [],
    "l10n-slot0" => [],
    "l10n-slot1" => [],
    "parsoid/Parsoid" => ["parsoid.config_symlink","parsoid.restart_parsoid"],
    "parsoid/config" => ["parsoid.restart_parsoid"],
  }
  # Should this repo also do a submodule update --init?
  $deployment_repo_checkout_submodules = {
    "common" => "False",
    "slot0" => "True",
    "slot1" => "True",
    "l10n-slot0" => "False",
    "l10n-slot1" => "False",
    "parsoid/Parsoid" => "False",
    "parsoid/config" => "False",
  }
  $deployment_repo_locations = {
    "common" => "/srv/deployment/mediawiki/common",
    "slot0" => "/srv/deployment/mediawiki/slot0",
    "slot1" => "/srv/deployment/mediawiki/slot1",
    "l10n-slot0" => "/srv/deployment/mediawiki/l10n-slot0",
    "l10n-slot1" => "/srv/deployment/mediawiki/l10n-slot1",
    "parsoid/Parsoid" => "/srv/deployment/parsoid/Parsoid",
    "parsoid/config" => "/srv/deployment/parsoid/config",
  }
  # ensure dependent repos are fetched and checked out with this repo
  # repos fetched/checkedout in order
  $deployment_repo_dependencies = {
    "slot0" => ["l10n-slot0"],
    "slot1" => ["l10n-slot1"],
  }
}

class role::deployment::salt_masters::production {
  $mediawiki_regex = "^(mw).*eqiad.*"
  $parsoid_regex = "^(wtp1|mexia|tola|lardner|kuo|celsus|constable|wtp1001)\..*"
  $deployment_servers = {
    "pmtpa" => "deployment.pmtpa.wmnet",
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
      "common"  => $mediawiki_regex,
      "slot0"   => $mediawiki_regex,
      "slot1"   => $mediawiki_regex,
      "l10n-slot0"   => $mediawiki_regex,
      "l10n-slot1"   => $mediawiki_regex,
      "parsoid/Parsoid" => $parsoid_regex,
      "parsoid/config" => $parsoid_regex,
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
      "common"  => $mediawiki_regex,
      "slot0"   => $mediawiki_regex,
      "slot1"   => $mediawiki_regex,
      "l10n-slot0"   => $mediawiki_regex,
      "l10n-slot1"   => $mediawiki_regex,
      "parsoid/Parsoid" => $parsoid_regex,
      "parsoid/config" => $parsoid_regex,
    },
    deployment_deploy_redis => {
      "host" => "i-00000390.pmtpa.wmflabs",
      "port" => 6379,
      "db" => "0",
    },
  }
}

class role::deployment::deployment_servers::common {
  include misc::deployment::scripts

  class { "deployment::deployment_server": }

  deployment::deployment_repo_sync_hook_link { "common": target => "shared.py" }
  deployment::deployment_repo_sync_hook_link { "slot0": target => "shared.py" }
  deployment::deployment_repo_sync_hook_link { "slot1": target => "shared.py" }
  deployment::deployment_repo_sync_hook_link { "l10n-slot0": target => "depends.py" }
  deployment::deployment_repo_sync_hook_link { "l10n-slot1": target => "depends.py" }
  deployment::deployment_repo_dependencies_link { "l10n-slot0": target => "l10n" }
  deployment::deployment_repo_dependencies_link { "l10n-slot1": target => "l10n" }
  deployment::deployment_repo_sync_hook_link { "parsoid/Parsoid": target => "shared.py" }
  deployment::deployment_repo_sync_hook_link { "parsoid/config": target => "shared.py" }

  class { "apache": }
  class {"apache::mod::dav": }
  class {"apache::mod::dav_fs": }

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
    docroot_dir_allows  => ["10.0.0.0/16","10.64.0.0/22","10.64.16.0/24","208.80.152.0/24"],
    serveradmin		=> "noc@wikimedia.org",
    configure_firewall 	=> false,
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
}
