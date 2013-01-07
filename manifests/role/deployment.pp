# Configuration shared by production and beta
class role::deployment::salt_masters::common {
		$deployment_repo_regex = {
      'common' => {},
      'slot0' => {
        'https://gerrit.wikimedia.org/r/p/mediawiki' => '__REPO_URL__/.git/modules',
        '.git' => '',
      },
      'slot1' => {
        'https://gerrit.wikimedia.org/r/p/mediawiki' => '__REPO_URL__/.git/modules',
        '.git' => '',
      },
      'parsoid/Parsoid' => {},
      'parsoid/config' => {},
    }

    # Maybe turn this into a hash so that modules can specify args too
    $deployment_repo_checkout_module_calls = {
      'common' => [],
      'slot0' => [],
      'slot1' => [],
      'parsoid/Parsoid' => ['parsoid.config_symlink','parsoid.restart_parsoid'],
      'parsoid/config' => ['parsoid.restart_parsoid'],
    }

    # Should this repo also do a submodule update --init?
    $deployment_repo_checkout_submodules = {
      'common' => 'False',
      'slot0' => 'True',
      'slot1' => 'True',
      'parsoid/Parsoid' => 'False',
      'parsoid/config' => 'False',
    }

    $deployment_repo_locations = {
      'common' => '/srv/deployment/mediawiki/common',
      'slot0' => '/srv/deployment/mediawiki/slot0',
      'slot1' => '/srv/deployment/mediawiki/slot1',
      'parsoid/Parsoid' => '/srv/deployment/parsoid/Parsoid',
      'parsoid/config' => '/srv/deployment/parsoid/config',
    }
}

class role::deployment::salt_masters::production {
	require role::deployment::salt_masters::common

  class { "deployment::salt_master":
    deployment_servers => ['tin.eqiad.wmnet'],
    deployment_minion_regex => {
      'common'  => '^(mw).*eqiad.*',
      'slot0'   => '^(mw).*eqiad.*',
      'slot1'   => '^(mw).*eqiad.*',
      'parsoid/Parsoid' => '^(wtp1|mexia|tola|lardner|kuo|celsus|constable|wtp1001)\..*',
      'parsoid/config' => '^(wtp1|mexia|tola|lardner|kuo|celsus|constable|wtp1001)\..*',
    },
    deployment_repo_urls => {
      'pmtpa' => {
        'common' => 'http://deployment.pmtpa.wmnet/mediawiki/common',
        'slot0' => 'http://deployment.pmtpa.wmnet/mediawiki/slot0',
        'slot1' => 'http://deployment.pmtpa.wmnet/mediawiki/slot1',
        'parsoid/Parsoid' => 'http://tin.eqiad.wmnet/parsoid/Parsoid',
        'parsoid/config' => 'http://tin.eqiad.wmnet/parsoid/config',
      },
      'eqiad' => {
        'common' => 'http://tin.eqiad.wmnet/mediawiki/common',
        'slot0' => 'http://tin.eqiad.wmnet/mediawiki/slot0',
        'slot1' => 'http://tin.eqiad.wmnet/mediawiki/slot1',
        'parsoid/Parsoid' => 'http://tin.eqiad.wmnet/parsoid/Parsoid',
        'parsoid/config' => 'http://tin.eqiad.wmnet/parsoid/config',
      },
    },
		deployment_repo_regex => $deployment_repo_regex,
    deployment_repo_checkout_module_calls => $deployment_repo_checkout_module_calls,
    deployment_repo_checkout_submodules => $deployment_repo_checkout_submodules,
    deployment_repo_locations => $deployment_repo_locations,
    deployment_deploy_redis => {
      'host' => 'tin.eqiad.wmnet',
      'port' => 6379,
      'db' => '0',
    },
  }
}

class role::deployment::salt_masters::beta {
	require role::deployment::salt_masters::common

	class { "deployment::salt_master":
		deployment_servers => ["deployment-bastion.pmtpa.wmflabs"],
		deployment_minion_regex => {
			'common'  => 'deployment-(apache|video|jobrunner).*',
			'slot0'   => 'deployment-(apache|video|jobrunner).*',
			'slot1'   => 'deployment-(apache|video|jobrunner).*',
			'parsoid/Parsoid' => '^$',  # No Parsoid on beta yet
			'parsoid/config'  => '^$',  # No Parsoid on beta yet
		},
		deployment_repo_urls => {
			'pmtpa' => {
				'common' => 'http://deploymnet-bastion.pmtpa.wmflabs/mediawiki/common',
				'slot0' => 'http://deploymnet-bastion.pmtpa.wmflabs/mediawiki/slot0',
				'slot1' => 'http://deploymnet-bastion.pmtpa.wmflabs/mediawiki/slot1',
			},
		},
		deployment_repo_regex => $deployment_repo_regex,
    deployment_repo_checkout_module_calls => $deployment_repo_checkout_module_calls,
    deployment_repo_checkout_submodules => $deployment_repo_checkout_submodules,
    deployment_repo_locations => $deployment_repo_locations,
		# No Redis on beta yet.
    deployment_deploy_redis => {},
	}
}


# Configuration shared by production and beta
class role::deployment::deployment_servers::common {
  class { "deployment::deployment_server": }

  deployment::deployment_repo_sync_hook_link { "common": }
  deployment::deployment_repo_sync_hook_link { "slot0": }
  deployment::deployment_repo_sync_hook_link { "slot1": }
  deployment::deployment_repo_sync_hook_link { "parsoid": }

  class { "apache": }
  class {'apache::mod::dav': }
  class {'apache::mod::dav_fs': }

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
	require role::deployment::deployment_servers::common

  apache::vhost { "tin.eqiad.wmnet":
    priority		=> 10,
    vhost_name		=> "10.64.0.196",
    port		=> 80,
    docroot		=> "/srv/deployment",
    docroot_dir_allows  => ['10.0.0.0/16','10.64.0.0/22','10.64.16.0/24','208.80.152.0/24'],
    serveradmin		=> "noc@wikimedia.org",
    configure_firewall 	=> false,
  }
}

class role::deployment::deployment_servers::beta {
	require role::deployment::deployment_servers::common

  apache::vhost { "deployment-bastion.pmtpa.wmflabs":
    priority		=> 10,
    vhost_name		=> "10.4.0.58", # deployment-bastion IP
    port		=> 80,
    docroot		=> "/srv/deployment",
		# Allow all labs instances. Not ideal though.
    docroot_dir_allows  => ['10.4.0.0/23'],
		# Just use the labs-l mailing list since we do not want wikimedia
		# ops to be spammed with non production issues.
    serveradmin		=> "labs-l@lists.wikimedia.org",
    configure_firewall 	=> false,
  }
}
