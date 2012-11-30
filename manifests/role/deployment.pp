class role::deployment::salt_masters::production {
  class { "deployment::salt_master":
    deployment_servers => ['tin.eqiad.wmnet'],
    deployment_minion_regex => '(mw).*eqiad.*',
    deployment_repo_urls => {
      'pmtpa' => {
        'common' => 'http://deployment.pmtpa.wmnet/deployment/common',
        'slot0' => 'http://deployment.pmtpa.wmnet/deployment/common/slot0',
        'slot1' => 'http://deployment.pmtpa.wmnet/deployment/common/slot1',
      },
      'eqiad' => {
        'common' => 'http://deployment.eqiad.wmnet/deployment/common',
        'slot0' => 'http://deployment.eqiad.wmnet/deployment/common/slot0',
        'slot1' => 'http://deployment.eqiad.wmnet/deployment/common/slot1',
      },
    },
    deployment_repo_regex => {
      'common' => {},
      'slot0' => {
        'https://gerrit.wikimedia.org/r/p/mediawiki' => '__REPO_URL__',
        '.git' => '/.git',
      },
      'slot1' => {
        'https://gerrit.wikimedia.org/r/p/mediawiki' => '__REPO_URL__',
        '.git' => '/.git',
      },
    },
    deployment_repo_locations => {
      'common' => '/usr/local/apache/common',
      'slot0' => '/usr/local/apache/common/slot0',
      'slot1' => '/usr/local/apache/common/slot0',
    },
  }
  deployment_repo_sync_hook_link { "common": }
  deployment_repo_sync_hook_link { "slot0": }
  deployment_repo_sync_hook_link { "slot1": }
}

class role::deployment::deployment_servers {
  class { "deployment::deployment_server": }
}
