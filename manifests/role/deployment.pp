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
    'integration/php-coveralls' => {
        'grain' => 'contint-production-slaves',
        'upstream' => 'https://gerrit.wikimedia.org/r/integration/php-coveralls',
    },
    'integration/slave-scripts' => {
        'grain' => 'contint-production-slaves',
        'upstream' => 'https://gerrit.wikimedia.org/r/integration/jenkins',
        'checkout_submodules'   => true,
    },
    'gdash/gdash'                    => {
        'grain'    => 'gdash',
        'upstream' => 'https://gerrit.wikimedia.org/r/operations/software/gdash',
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
    'rcstream/rcstream' => {
        'grain'                 => 'rcstream',
        'upstream'              => 'https://gerrit.wikimedia.org/r/mediawiki/services/rcstream',
        'service_name'          => 'rcstream',
    },
    'fluoride/fluoride'              => {
        'grain'    => 'eventlogging',
        'upstream' => 'https://gerrit.wikimedia.org/r/mediawiki/tools/fluoride',
    },
    'mwprof/mwprof'                  => {
        'grain'    => 'mwprof',
        'upstream' => 'https://gerrit.wikimedia.org/r/operations/software/mwprof',
    },
    'reporter/reporter'              => {
        'grain'    => 'reporter',
        'upstream' => 'https://gerrit.wikimedia.org/r/operations/software/mwprof/reporter',
    },
    'test/testrepo'                  => {
        'grain'               => 'testrepo',
        'service_name'        => 'puppet',
        'checkout_submodules' => true,
        'gitfat_enabled'      => true,
    },
    'elasticsearch/plugins'          => {
        'grain'          => 'elasticsearchplugins',
        'gitfat_enabled' => true,
        'upstream'       => 'https://gerrit.wikimedia.org/r/operations/software/elasticsearch/plugins',
    },
    'analytics/kraken/deploy'        => {
        'grain'               => 'analytics-kraken-deploy',
        'gitfat_enabled'      => true,
        'checkout_submodules' => true,
        'upstream'            => 'https://gerrit.wikimedia.org/r/p/analytics/kraken/deploy',
    },
    'analytics/refinery'        => {
        'grain'               => 'analytics-refinery',
        'gitfat_enabled'      => true,
        'upstream'            => 'https://gerrit.wikimedia.org/r/analytics/refinery',
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
    'scap/scap' => {
        'grain'    => 'scap',
        'upstream' => 'https://gerrit.wikimedia.org/r/mediawiki/tools/scap',
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

  class { 'deployment::deployment_server':
    deployer_groups => ['wikidev'],
  }

  class { 'apache': }
  class { 'apache::mod::dav': }
  class { 'apache::mod::dav_fs': }

  class { 'mediawiki::packages': }

  apache::vhost { 'default':
    ensure              => absent,
    priority            => '000',
    port                => '80',
    docroot             => '/var/www',
    configure_firewall  => false,
  }
}

class role::deployment::deployment_servers::production {
  include role::deployment::deployment_servers::common
  include network::constants

  apache::vhost { 'tin.eqiad.wmnet':
    priority             => '10',
    vhost_name           => '10.64.0.196',
    port                 => '80',
    docroot              => '/srv/deployment',
    docroot_owner        => 'trebuchet',
    docroot_group        => 'wikidev',
    docroot_dir_allows   => $::network::constants::mw_appserver_networks,
    serveradmin          => 'noc@wikimedia.org',
    configure_firewall   => false,
  }
  class { 'redis':
    dir => '/srv/redis',
    maxmemory => '500Mb',
    monitor => true,
  }
  package { 'percona-toolkit':
    ensure => latest,
  }
  sudo_group { 'wikidev_deployment_server':
    privileges => [
      'ALL = (root) NOPASSWD: /usr/bin/salt-call -l quiet --out=json pillar.data',
      'ALL = (root) NOPASSWD: /usr/bin/salt-call -l quiet publish.runner deploy.fetch *',
      'ALL = (root) NOPASSWD: /usr/bin/salt-call -l quiet publish.runner deploy.checkout *',
      'ALL = (root) NOPASSWD: /usr/bin/salt-call -l quiet --out=json publish.runner deploy.restart *',
    ],
    group => 'wikidev',
  }
}

class role::deployment::salt_masters::labs {
  # Enable multiple test environments within a single project
  if ( $::deployment_server_override != undef ) {
    $deployment_server = $::deployment_server_override
  } else {
    $deployment_server = "${::instanceproject}-deploy.eqiad.wmflabs"
  }
  $deployment_config = {
    'parent_dir' => '/srv/deployment',
    'servers'    => {
       'pmtpa'  => $deployment_server,
       'eqiad'  => $deployment_server,
    },
    'redis'      => {
     'host'     => $deployment_server,
     'port'     => '6379',
     'db'       => '0',
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
    $deployment_server = "${::instanceproject}-deploy.eqiad.wmflabs"
  }
  apache::vhost { $deployment_server:
    priority            => '10',
    port                => '80',
    docroot             => '/srv/deployment',
    docroot_owner       => 'trebuchet',
    docroot_group       => "project-${::instanceproject}",
    docroot_dir_allows  => ['10.0.0.0/8'],
    serveradmin         => 'noc@wikimedia.org',
    configure_firewall  => false,
  }
  class { 'redis':
    dir       => '/srv/redis',
    maxmemory => '500Mb',
    monitor   => false,
  }
  sudo_group { "project_${::instanceproject}_deployment_server":
    privileges => [
      'ALL = (root) NOPASSWD: /usr/bin/salt-call -l quiet --out=json pillar.data',
      'ALL = (root) NOPASSWD: /usr/bin/salt-call -l quiet publish.runner deploy.fetch *',
      'ALL = (root) NOPASSWD: /usr/bin/salt-call -l quiet publish.runner deploy.checkout *',
      'ALL = (root) NOPASSWD: /usr/bin/salt-call -l quiet --out=json publish.runner deploy.restart *',
    ],
    group => "project-${::instanceproject}",
  }
}

class role::deployment::test {
    deployment::target { 'testrepo': }
}
