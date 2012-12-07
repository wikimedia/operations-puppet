class role::deployment::salt_masters::production {
  class { "deployment::salt_master":
    deployment_servers => ['tin.eqiad.wmnet'],
    deployment_minion_regex => {
      'common'  => '^(mw).*eqiad.*',
      'slot0'   => '^(mw).*eqiad.*',
      'slot1'   => '^(mw).*eqiad.*',
      'parsoid' => '^(wtp1|mexia|tola|lardner|kuo|wtp1001)\..*',
    }
    deployment_repo_urls => {
      'pmtpa' => {
        'common' => 'http://deployment.pmtpa.wmnet/mediawiki/common',
        'slot0' => 'http://deployment.pmtpa.wmnet/mediawiki/slot0',
        'slot1' => 'http://deployment.pmtpa.wmnet/mediawiki/slot1',
      },
      'eqiad' => {
        'common' => 'http://tin.eqiad.wmnet/mediawiki/common',
        'slot0' => 'http://tin.eqiad.wmnet/mediawiki/slot0',
        'slot1' => 'http://tin.eqiad.wmnet/mediawiki/slot1',
      },
    },
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
    },
    deployment_repo_locations => {
      'common' => '/srv/deployment/mediawiki/common',
      'slot0' => '/srv/deployment/mediawiki/slot0',
      'slot1' => '/srv/deployment/mediawiki/slot1',
    },
  }
}

class role::deployment::deployment_servers {
  class { "deployment::deployment_server": }

  deployment::deployment_repo_sync_hook_link { "common": }
  deployment::deployment_repo_sync_hook_link { "slot0": }
  deployment::deployment_repo_sync_hook_link { "slot1": }

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
    docroot_dir_denies  => ['all'],
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
