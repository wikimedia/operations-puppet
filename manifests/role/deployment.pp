# vim: sw=2 ts=2 et
class role::deployment::config {
  $repo_config = {
    'common'                         => {
        'grain' => 'mediawiki',
    },
    'private'                        => {
        'grain' => 'mediawiki',
    },
    'slot0'                          => {
        'grain'               => 'mediawiki',
        'submodule_sed_regex' => {
          'https://gerrit.wikimedia.org/r/p/mediawiki' => '__REPO_URL__/.git/modules',
          '.git' => '',
        },
        'checkout_submodules' => true,
        'dependencies'        => {
            'l10n-slot0' => 'l10n',
        },
    },
    'slot1'                          => {
        'grain' => 'mediawiki',
        'submodule_sed_regex' => {
          'https://gerrit.wikimedia.org/r/p/mediawiki' => '__REPO_URL__/.git/modules',
          '.git' => '',
        },
        'checkout_submodules' => true,
        'dependencies'        => {
            'l10n-slot1' => 'l10n',
        },
    },
    'beta0'                          => {
        'grain' => 'mediawiki',
        'submodule_sed_regex' => {
          'https://gerrit.wikimedia.org/r/p/mediawiki' => '__REPO_URL__/.git/modules',
          '.git' => '',
        },
        'checkout_submodules' => true,
        'dependencies'        => {
            'l10n-beta' => 'l10n',
        },
    },
    'l10n-slot0'                     => {
        'automated' => true,
        'grain'     => 'mediawiki',
    },
    'l10n-slot1'                     => {
        'automated' => true,
        'grain'     => 'mediawiki',
    },
    'l10n-beta0'                     => {
        'automated' => true,
        'grain'     => 'mediawiki',
    },
    'gdash/gdash'                    => {
        'grain' => 'gdash',
    },
    'parsoid/Parsoid'                => {
        'grain'                 => 'parsoid',
        'checkout_module_calls' => {
            'parsoid.config_symlink'  => ['__REPO__'],
            'parsoid.restart_parsoid' => ['__REPO__'],
        },
    },
    'parsoid/config'                 => {
        'grain'                 => 'parsoid',
        'checkout_module_calls' => {
            'parsoid.restart_parsoid' => ['__REPO__'],
        },
    },
    'eventlogging/EventLogging'      => {
        'grain' => 'eventlogging',
    },
    'fluoride/fluoride'              => {
        'grain' => 'fluoride',
    },
    'test/testrepo'                  => {
        'grain' => 'testrepo',
    },
    'elasticsearch/plugins'          => {
        'grain' => 'elasticsearchplugins',
    },
    'analytics/kraken'               => {
        'grain' => 'analytics-kraken',
    },
  }
}

class role::deployment::salt_masters::production {
  $deployment_config = {
    'parent_dir' => '/srv/deployment',
    'servers'        => {
        'pmtpa' => 'tin.eqiad.wmnet',
        'eqiad' => 'tin.eqiad.wmnet',
    },
    'redis'          => {
      'host' => 'tin.eqiad.wmnet',
      'port' => '6379',
      'db'   => '0',
    },
  }
  class { '::role::deployment::config': }
  class { 'deployment::salt_master':
    repo_config       => $role::deployment::config::repo_config,
    deployment_config => $deployment_config,
  }
}

class role::deployment::salt_masters::labs {
  $deployment_config = {
    'parent_dir' => '/srv/deployment',
    'servers'        => {
        'pmtpa' => 'i-00000390.pmtpa.wmflabs',
        'eqiad' => 'i-00000390.pmtpa.wmflabs',
    },
    'redis'          => {
      'host' => 'i-00000390.pmtpa.wmflabs',
      'port' => '6379',
      'db'   => '0',
    },
  }
  class { '::role::deployment::config': }
  class { 'deployment::salt_master':
    repo_config       => $role::deployment::config::repo_config,
    deployment_config => $deployment_config,
  }
}

class role::deployment::salt_masters::sartoris {
  $deployment_config = {
    'parent_dir' => '/srv/deployment',
    'servers'        => {
        'pmtpa' => 'i-00000822.pmtpa.wmflabs',
        'eqiad' => 'i-00000822.pmtpa.wmflabs',
    },
    'redis'          => {
      'host' => 'i-00000822.pmtpa.wmflabs',
      'port' => '6379',
      'db'   => '0',
    },
  }
  class { '::role::deployment::config': }
  class { 'deployment::salt_master':
    repo_config       => $role::deployment::config::repo_config,
    deployment_config => $deployment_config,
  }
}

class role::deployment::deployment_servers::common {
  # Can't include this while scap is present on tin:
  # include misc::deployment::scripts

  class { "deployment::deployment_server":
    deployer_groups => ['wikidev'],
  }

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

class role::deployment::deployment_servers::sartoris {
  include role::deployment::deployment_servers::common

  apache::vhost { "i-00000822.pmtpa.wmflabs":
    priority		=> 10,
    vhost_name		=> "10.4.1.19",
    port		=> 80,
    docroot		=> "/srv/deployment",
    docroot_group	=> "project-sartoris",
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
    group => "project-sartoris",
  }
}

class role::deployment::test {
    deployment::target { 'testrepo': }
}
