class role::deployment::salt_masters::production {
  class { "deployment::salt_master":
    deployment_servers => ['tin.eqiad.wmnet'],
    deployment_minion_regex => {
      'common'  => '^(mw).*eqiad.*',
      'slot0'   => '^(mw).*eqiad.*',
      'slot1'   => '^(mw).*eqiad.*',
      'l10n-slot0'   => '^(mw).*eqiad.*',
      'l10n-slot1'   => '^(mw).*eqiad.*',
      'parsoid/Parsoid' => '^(wtp1|mexia|tola|lardner|kuo|celsus|constable|wtp1001)\..*',
      'parsoid/config' => '^(wtp1|mexia|tola|lardner|kuo|celsus|constable|wtp1001)\..*',
    },
    deployment_repo_urls => {
      'pmtpa' => {
        'common' => 'http://deployment.pmtpa.wmnet/mediawiki/common',
        'slot0' => 'http://deployment.pmtpa.wmnet/mediawiki/slot0',
        'slot1' => 'http://deployment.pmtpa.wmnet/mediawiki/slot1',
        'l10n-slot0' => 'http://deployment.pmtpa.wmnet/mediawiki/l10n-slot0',
        'l10n-slot1' => 'http://deployment.pmtpa.wmnet/mediawiki/l10n-slot1',
        'parsoid/Parsoid' => 'http://tin.eqiad.wmnet/parsoid/Parsoid',
        'parsoid/config' => 'http://tin.eqiad.wmnet/parsoid/config',
      },
      'eqiad' => {
        'common' => 'http://tin.eqiad.wmnet/mediawiki/common',
        'slot0' => 'http://tin.eqiad.wmnet/mediawiki/slot0',
        'slot1' => 'http://tin.eqiad.wmnet/mediawiki/slot1',
        'l10n-slot0' => 'http://tin.eqiad.wmnet/mediawiki/l10n-slot0',
        'l10n-slot1' => 'http://tin.eqiad.wmnet/mediawiki/l10n-slot1',
        'parsoid/Parsoid' => 'http://tin.eqiad.wmnet/parsoid/Parsoid',
        'parsoid/config' => 'http://tin.eqiad.wmnet/parsoid/config',
      },
    },
    # Sed the .gitmodules file for the repo according to the following rules
    # TODO: rename this to something more specific
    deployment_repo_regex => {
      'common' => {},
      'slot0' => {
        'https://gerrit.wikimedia.org/r/p/mediawiki' => '__REPO_URL__/.git/modules',
        '.git' => '',
      },
      'slot1' => {
        'https://gerrit.wikimedia.org/r/p/mediawiki' => '__REPO_URL__/.git/modules',
        '.git' => '',
      },
      'l10n-slot0' => {},
      'l10n-slot1' => {},
      'parsoid/Parsoid' => {},
      'parsoid/config' => {},
    },
    # Call these salt modules after checkout of parent repo and submodules
    # TODO: turn this into a hash so that modules can specify args too
    deployment_repo_checkout_module_calls => {
      'common' => [],
      'slot0' => [],
      'slot1' => [],
      'l10n-slot0' => [],
      'l10n-slot1' => [],
      'parsoid/Parsoid' => ['parsoid.config_symlink','parsoid.restart_parsoid'],
      'parsoid/config' => ['parsoid.restart_parsoid'],
    },
    # Should this repo also do a submodule update --init?
    deployment_repo_checkout_submodules => {
      'common' => 'False',
      'slot0' => 'True',
      'slot1' => 'True',
      'l10n-slot0' => 'False',
      'l10n-slot1' => 'False',
      'parsoid/Parsoid' => 'False',
      'parsoid/config' => 'False',
    },
    deployment_repo_locations => {
      'common' => '/srv/deployment/mediawiki/common',
      'slot0' => '/srv/deployment/mediawiki/slot0',
      'slot1' => '/srv/deployment/mediawiki/slot1',
      'l10n-slot0' => '/srv/deployment/mediawiki/l10n-slot0',
      'l10n-slot1' => '/srv/deployment/mediawiki/l10n-slot1',
      'parsoid/Parsoid' => '/srv/deployment/parsoid/Parsoid',
      'parsoid/config' => '/srv/deployment/parsoid/config',
    },
    # ensure dependent repos are fetched and checked out with this repo
    # repos fetched/checkedout in order
    deployment_repo_dependencies => {
      'slot0' => ['l10n-slot0'],
      'slot1' => ['l10n-slot1'],
    },
    deployment_deploy_redis => {
      'host' => 'tin.eqiad.wmnet',
      'port' => 6379,
      'db' => '0',
    },
  }
}

class role::deployment::deployment_servers {
  class { "deployment::deployment_server": }

  deployment::deployment_repo_sync_hook_link { "common": "shared.py" }
  deployment::deployment_repo_sync_hook_link { "slot0": "shared.py" }
  deployment::deployment_repo_sync_hook_link { "slot1": "shared.py" }
  deployment::deployment_repo_sync_hook_link { "l10n-slot0": "depends.py" }
  deployment::deployment_repo_sync_hook_link { "l10n-slot1": "depends.py" }
  deployment::deployment_repo_sync_hook_link { "parsoid": "shared.py" }

  class { "apache": }
  class {'apache::mod::dav': }
  class {'apache::mod::dav_fs': }

  class { "applicationserver::packages": }

  apache::vhost { "tin.eqiad.wmnet":
    priority		=> 10,
    vhost_name		=> "10.64.0.196",
    port		=> 80,
    docroot		=> "/srv/deployment",
    docroot_dir_allows  => ['10.0.0.0/16','10.64.0.0/22','10.64.16.0/24','208.80.152.0/24'],
    serveradmin		=> "noc@wikimedia.org",
    configure_firewall 	=> false,
  }

  apache::vhost { "default":
    priority		=> 000,
    port		=> 80,
    docroot		=> "/var/www",
    ensure		=> absent,
    configure_firewall 	=> false,
  }
}
