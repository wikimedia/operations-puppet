# vim: sw=2 ts=2 et
class role::deployment::config($deployment_servers) {
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
      "gdash/gdash" => "http://${deploy_server_pmtpa}/gdash/gdash",
      "elasticsearch/plugins" => "http://${deploy_server_pmtpa}/elasticsearch/plugins",
      # parsoid, fluoride and eventlogging are currently eqiad-only:
      "parsoid/Parsoid" => "http://${deploy_server_eqiad}/parsoid/Parsoid",
      "parsoid/config" => "http://${deploy_server_eqiad}/parsoid/config",
      "eventlogging/EventLogging" => "http://${deploy_server_eqiad}/eventlogging/EventLogging",
      "fluoride/fluoride" => "http://${deploy_server_eqiad}/fluoride/fluoride",
      "test/testrepo" => "http://${deploy_server_eqiad}/test/testrepo",
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
      "gdash/gdash" => "http://${deploy_server_eqiad}/gdash/gdash",
      "parsoid/Parsoid" => "http://${deploy_server_eqiad}/parsoid/Parsoid",
      "parsoid/config" => "http://${deploy_server_eqiad}/parsoid/config",
      "eventlogging/EventLogging" => "http://${deploy_server_eqiad}/eventlogging/EventLogging",
      "fluoride/fluoride" => "http://${deploy_server_eqiad}/fluoride/fluoride",
      "test/testrepo" => "http://${deploy_server_eqiad}/test/testrepo",
      "elasticsearch/plugins" => "http://${deploy_server_eqiad}/elasticsearch/plugins",
      'analytics/kraken' => "http://${deploy_server_eqiad}/analytics/kraken",
    },
  }
  # deployment_target grain value for this repo. This must match the deployment::target
  # value that is being set on the targets via puppet. If unset, the default value
  # is the repo name
  $deployment_repo_grains = {
    "common" => "mediawiki",
    "private" => "mediawiki",
    "slot0" => "mediawiki",
    "slot1" => "mediawiki",
    "beta0" => "mediawiki",
    "l10n-slot0" => "mediawiki",
    "l10n-slot1" => "mediawiki",
    "l10n-beta0" => "mediawiki",
    "gdash/gdash" => "gdash",
    "parsoid/Parsoid" => "parsoid",
    "parsoid/config" => "parsoid",
    "eventlogging/EventLogging" => "eventlogging",
    "fluoride/fluoride" => "fluoride",
    "test/testrepo" => "testrepo",
    "elasticsearch/plugins" => "elasticsearchplugins",
    'analytics/kraken' => 'analytics-kraken',
  }
  # Sed the .gitmodules file for the repo according to the following rules
  # TODO: rename this to something more specific
  $deployment_repo_regex = {
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
  }
  # Call these salt modules after checkout of parent repo and submodules
  # TODO: turn this into a hash so that modules can specify args too
  $deployment_repo_checkout_module_calls = {
    "parsoid/Parsoid" => ["parsoid.config_symlink","parsoid.restart_parsoid"],
    "parsoid/config" => ["parsoid.restart_parsoid"],
  }
  # Should this repo also do a submodule update --init?
  $deployment_repo_checkout_submodules = {
    "slot0" => "True",
    "slot1" => "True",
    "beta0" => "True",
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
    "gdash/gdash" => "/srv/deployment/gdash/gdash",
    "parsoid/Parsoid" => "/srv/deployment/parsoid/Parsoid",
    "parsoid/config" => "/srv/deployment/parsoid/config",
    "eventlogging/EventLogging" => "/srv/deployment/eventlogging/EventLogging",
    "fluoride/fluoride" => "/srv/deployment/fluoride/fluoride",
    "test/testrepo" => "/srv/deployment/test/testrepo",
    "elasticsearch/plugins" => "/srv/deployment/elasticsearch/plugins",
    'analytics/kraken' => '/srv/analytics/kraken',
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
  $deployment_servers = {
    "pmtpa" => "tin.eqiad.wmnet",
    "eqiad" => "tin.eqiad.wmnet",
  }
  class { "::role::deployment::config":
    deployment_servers => $deployment_servers,
  }
  class { "deployment::salt_master":
    deployment_servers => $deployment_servers,
    deployment_repo_urls => $role::deployment::config::deployment_repo_urls,
    deployment_repo_regex => $role::deployment::config::deployment_repo_regex,
    deployment_repo_checkout_module_calls => $role::deployment::config::deployment_repo_checkout_module_calls,
    deployment_repo_checkout_submodules => $role::deployment::config::deployment_repo_checkout_submodules,
    deployment_repo_locations => $role::deployment::config::deployment_repo_locations,
    deployment_repo_dependencies => $role::deployment::config::deployment_repo_dependencies,
    deployment_repo_grains => $role::deployment::config::deployment_repo_grains,
    deployment_deploy_redis => {
      "host" => "tin.eqiad.wmnet",
      "port" => 6379,
      "db" => "0",
    },
  }
}

class role::deployment::salt_masters::labs {
  $deployment_servers = {
    "pmtpa" => "i-00000390.pmtpa.wmflabs",
    # no eqiad zone, yet
    "eqiad" => "i-00000390.pmtpa.wmflabs",
  }
  class { "role::deployment::config":
    deployment_servers => $deployment_servers,
  }
  class { "deployment::salt_master":
    deployment_servers => $deployment_servers,
    deployment_repo_urls => $role::deployment::config::deployment_repo_urls,
    deployment_repo_regex => $role::deployment::config::deployment_repo_regex,
    deployment_repo_checkout_module_calls => $role::deployment::config::deployment_repo_checkout_module_calls,
    deployment_repo_checkout_submodules => $role::deployment::config::deployment_repo_checkout_submodules,
    deployment_repo_locations => $role::deployment::config::deployment_repo_locations,
    deployment_repo_dependencies => $role::deployment::config::deployment_repo_dependencies,
    deployment_repo_grains => $role::deployment::config::deployment_repo_grains,
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

  class { "deployment::deployment_server":
    deployer_groups => ['wikidev'],
  }

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
  deployment::deployment_repo_sync_hook_link { "gdash/gdash": target => "shared.py" }
  deployment::deployment_repo_sync_hook_link { "parsoid/Parsoid": target => "shared.py" }
  deployment::deployment_repo_sync_hook_link { "parsoid/config": target => "shared.py" }
  deployment::deployment_repo_sync_hook_link { "eventlogging/EventLogging": target => "shared.py" }
  deployment::deployment_repo_sync_hook_link { "fluoride/fluoride": target => "shared.py" }
  deployment::deployment_repo_sync_hook_link { "test/testrepo": target => "shared.py" }
  deployment::deployment_repo_sync_hook_link { "elasticsearch/plugins": target => "shared.py" }
  deployment::deployment_repo_sync_hook_link { 'analytics/kraken': target => "shared.py" }

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
    docroot_group	=> "wikidev",
    docroot_dir_allows  => ["10.0.0.0/16","10.64.0.0/16","208.80.152.0/22"],
    serveradmin		=> "noc@wikimedia.org",
    configure_firewall 	=> false,
  }
  class { "redis":
    dir => "/srv/redis",
    maxmemory => "500Mb",
    monitor => "true",
  }
  package { "percona-toolkit":
    ensure => latest;
  }
  sudo_group { "wikidev_deployment_server":
    privileges => [
      "ALL = (root) NOPASSWD: /usr/bin/salt-call -l quiet --out json pillar.data",
      "ALL = (root) NOPASSWD: /usr/bin/salt-call -l quiet publish.runner deploy.fetch *",
      "ALL = (root) NOPASSWD: /usr/bin/salt-call -l quiet publish.runner deploy.checkout *",
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
      "ALL = (root) NOPASSWD: /usr/bin/salt-call -l quiet --out json pillar.data",
      "ALL = (root) NOPASSWD: /usr/bin/salt-call -l quiet publish.runner deploy.fetch *",
      "ALL = (root) NOPASSWD: /usr/bin/salt-call -l quiet publish.runner deploy.checkout *",
    ],
    group => "project-deployment-prep",
  }
}

class role::deployment::test {
    deployment::target { 'testrepo': }
}
