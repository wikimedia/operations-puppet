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
    'jobrunner/jobrunner'            => {
        'grain'        => 'jobrunner',
        'upstream'     => 'https://gerrit.wikimedia.org/r/mediawiki/services/jobrunner',
        'service_name' => 'jobrunner',
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
    'mathoid/mathoid' => {
        'grain'                 => 'mathoid',
        'upstream'              => 'https://gerrit.wikimedia.org/r/mediawiki/services/mathoid',
        'service_name'          => 'mathoid',
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
    'servermon/servermon'            => {
        'grain'        => 'servermon',
        'service_name' => 'servermon',
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

  include ::apache
  include ::apache::mod::dav
  include ::apache::mod::dav_fs

  class { 'mediawiki::packages': }

  #RT 7427
  ::monitoring::icinga::git_merge { 'mediawiki_config':
      dir           => '/srv/mediawiki-staging/',
      user          => 'root',
      remote_branch => 'readonly/master'
  }
}

class role::deployment::deployment_servers::production {
  include role::deployment::deployment_servers::common
  include network::constants
  include wikitech::wiki::passwords

  file { '/srv/deployment':
    ensure => directory,
    owner  => 'trebuchet',
    group  => 'wikidev',
  }
  $deployable_networks = $::network::constants::deployable_networks
  $apache_fqdn = $::fqdn
  apache::site { 'deployment':
    content => template('apache/sites/deployment.erb'),
    require => File['/srv/deployment'],
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
    $apache_fqdn = $::deployment_server_override
  } else {
    $apache_fqdn = "${::instanceproject}-deploy.eqiad.wmflabs"
  }

  $deployable_networks = '10.0.0.0/8'

  file { '/srv/deployment':
    ensure => directory,
    owner  => 'trebuchet',
    group  => "project-${::instanceproject}",
  }
  apache::site { 'deployment':
    content => template('apache/sites/deployment.erb'),
    require => File['/srv/deployment'],
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
