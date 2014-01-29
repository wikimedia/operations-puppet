# vim: sw=2 ts=2 et

# Configuration info: https://wikitech.wikimedia.org/wiki/Trebuchet#Adding_a_new_repo
# Troubleshooting: https://wikitech.wikimedia.org/wiki/Trebuchet#Troubleshooting
class role::deployment::config {
  $repo_config = {
    'integration/kss' => {
        'grain' => 'contint-production-slaves',
        'upstream' => 'https://gerrit.wikimedia.org/r/integration/kss',
    },
    'integration/mediawiki-tools-codesniffer' => {
        'grain' => 'contint-production-slaves',
        'upstream' => 'https://gerrit.wikimedia.org/r/mediawiki/tools/codesniffer',
    },
    'integration/phpunit' => {
        'grain' => 'contint-production-slaves',
        'upstream' => 'https://gerrit.wikimedia.org/r/integration/phpunit',
    },
    'integration/phpcs' => {
        'grain' => 'contint-production-slaves',
        'upstream' => 'https://gerrit.wikimedia.org/r/integration/phpcs',
    },
    'integration/slave-scripts' => {
        'grain' => 'contint-production-slaves',
        'upstream' => 'https://gerrit.wikimedia.org/r/integration/jenkins',
        'checkout_submodules'   => true,
    },
    'mediawiki/common'               => {
        'grain'            => 'mediawiki',
        'upstream'         => 'https://gerrit.wikimedia.org/r/operations/mediawiki-config',
        'shadow_reference' => true,
    },
    'mediawiki/private'              => {
        'grain' => 'mediawiki',
    },
    'mediawiki/slot0'                => {
        'grain'                 => 'mediawiki',
        'upstream'              => 'https://gerrit.wikimedia.org/r/mediawiki/core',
        'checkout_submodules'   => true,
        'shadow_reference'      => true,
        'fetch_module_calls' => {
            'mediawiki.generate_localization_cache' => ['__REPO__'],
        },
        'checkout_module_calls' => {
            'mediawiki.update_localization_cache' => ['__REPO__'],
        },
    },
    'mediawiki/slot1'                => {
        'grain'                 => 'mediawiki',
        'upstream'              => 'https://gerrit.wikimedia.org/r/mediawiki/core',
        'checkout_submodules'   => true,
        'shadow_reference'      => true,
        'fetch_module_calls' => {
            'mediawiki.generate_localization_cache' => ['__REPO__'],
        },
        'checkout_module_calls' => {
            'mediawiki.update_localization_cache' => ['__REPO__'],
        },
    },
    'mediawiki/beta0'                => {
        'grain'                 => 'mediawiki',
        'upstream'              => 'https://gerrit.wikimedia.org/r/mediawiki/core',
        'checkout_submodules'   => true,
        'shadow_reference'      => true,
        'fetch_module_calls' => {
            'mediawiki.generate_localization_cache' => ['__REPO__'],
        },
        'checkout_module_calls' => {
            'mediawiki.update_localization_cache' => ['__REPO__'],
        },
    },
    'gdash/gdash'                    => {
        'grain'    => 'gdash',
        'upstream' => 'https://gerrit.wikimedia.org/r/operations/software/gdash',
    },
    'parsoid/Parsoid'                => {
        'grain'                 => 'parsoid',
        'upstream'              => 'https://gerrit.wikimedia.org/r/mediawiki/extensions/Parsoid',
        'checkout_module_calls' => {
            'parsoid.config_symlink'  => ['__REPO__'],
        },
        'service_name'          => 'parsoid',
    },
    'parsoid/config'                 => {
        'grain'                 => 'parsoid',
    },
    'parsoid/deploy'                => {
        'grain'                 => 'parsoid',
        'upstream'              => 'https://gerrit.wikimedia.org/r/p/mediawiki/services/parsoid/deploy',
        'checkout_submodules'   => true,
        'service_name'          => 'parsoid',
    },
    'eventlogging/EventLogging'      => {
        'grain'    => 'eventlogging',
        'upstream' => 'https://gerrit.wikimedia.org/r/mediawiki/extensions/EventLogging',
    },
    'ocg/ocg' => {
        'grain'                 => 'ocg',
        'upstream'              => 'https://gerrit.wikimedia.org/r/mediawiki/services/ocg-collection',
        'service_name'          => 'ocg',
        'checkout_submodules'   => true,
    },
    'fluoride/fluoride'              => {
        'grain'    => 'fluoride',
        'upstream' => 'https://gerrit.wikimedia.org/r/mediawiki/tools/fluoride',
    },
    'mwprof/mwprof'                  => {
        'grain'    => 'mwprof',
        'upstream' => 'https://gerrit.wikimedia.org/r/operations/software/mwprof',
    },
    'test/testrepo'                  => {
        'grain'        => 'testrepo',
        'service_name' => 'puppet',
    },
    'elasticsearch/plugins'          => {
        'grain'    => 'elasticsearchplugins',
        'upstream' => 'https://gerrit.wikimedia.org/r/operations/software/elasticsearch/plugins',
    },
    'analytics/kraken'               => {
        'grain'    => 'analytics-kraken',
        'upstream' => 'https://gerrit.wikimedia.org/r/p/analytics/kraken',
    },
    'scholarships/scholarships'      => {
        'grain'    => 'scholarships',
        'upstream' => 'https://gerrit.wikimedia.org/r/wikimedia/wikimania-scholarships',
    },
    'librenms/librenms'                  => {
        'grain'    => 'librenms',
        'upstream' => 'https://gerrit.wikimedia.org/r/operations/software/librenms',
    },
    'kibana/kibana'      => {
        'grain'    => 'kibana',
        'upstream' => 'https://gerrit.wikimedia.org/r/operations/software/kibana',
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
    docroot_owner	=> "trebuchet",
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
      "ALL = (root) NOPASSWD: /usr/bin/salt-call -l quiet --out json publish.runner deploy.restart *",
    ],
    group => "wikidev",
  }
}

class role::deployment::salt_masters::labs {
  # Enable multiple test environments within a single project
  if ( $::deployment_server_override != undef ) {
    $deployment_server = $::deployment_server_override
  } else {
    $deployment_server = "${::instanceproject}-deploy.pmtpa.wmflabs"
  }
  $deployment_config = {
    'parent_dir' => '/srv/deployment',
    'servers'        => {
        'pmtpa' => $deployment_server,
        'eqiad' => $deployment_server,
    },
    'redis'          => {
      'host' => $deployment_server,
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

class role::deployment::deployment_servers::labs {
  include role::deployment::deployment_servers::common

  # Enable multiple test environments within a single project
  if ( $::deployment_server_override != undef ) {
    $deployment_server = $::deployment_server_override
  } else {
    $deployment_server = "${::instanceproject}-deploy.pmtpa.wmflabs"
  }
  apache::vhost { $deployment_server:
    priority		=> 10,
    port		=> 80,
    docroot		=> "/srv/deployment",
    docroot_owner	=> "${::instanceproject}",
    docroot_group	=> "project-${::instanceproject}",
    docroot_dir_allows  => ["10.4.0.0/16"],
    serveradmin		=> "noc@wikimedia.org",
    configure_firewall 	=> false,
  }
  class { "redis":
    dir => "/srv/redis",
    maxmemory => "500Mb",
    monitor => "false",
  }
  sudo_group { "project_${::instanceproject}_deployment_server":
    privileges => [
      "ALL = (root) NOPASSWD: /usr/bin/salt-call -l quiet --out json pillar.data",
      "ALL = (root) NOPASSWD: /usr/bin/salt-call -l quiet publish.runner deploy.fetch *",
      "ALL = (root) NOPASSWD: /usr/bin/salt-call -l quiet publish.runner deploy.checkout *",
      "ALL = (root) NOPASSWD: /usr/bin/salt-call -l quiet --out json publish.runner deploy.restart *",
    ],
    group => "project-${::instanceproject}",
  }
}

class role::deployment::test {
    deployment::target { 'testrepo': }
}
