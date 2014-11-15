# Configuration info: https://wikitech.wikimedia.org/wiki/Trebuchet#Adding_a_new_repo
# Troubleshooting: https://wikitech.wikimedia.org/wiki/Trebuchet#Troubleshooting
class role::deployment::config {
    $repo_config = {
        'integration/kss' => {
            'upstream' => 'https://gerrit.wikimedia.org/r/integration/kss',
        },
        'integration/mediawiki-tools-codesniffer' => {
            'upstream' => 'https://gerrit.wikimedia.org/r/mediawiki/tools/codesniffer',
        },
        'integration/phpunit' => {
            'upstream' => 'https://gerrit.wikimedia.org/r/integration/phpunit',
        },
        'integration/phpcs' => {
            'upstream' => 'https://gerrit.wikimedia.org/r/integration/phpcs',
        },
        'integration/php-coveralls' => {
            'upstream' => 'https://gerrit.wikimedia.org/r/integration/php-coveralls',
        },
        'integration/slave-scripts' => {
            'upstream' => 'https://gerrit.wikimedia.org/r/integration/jenkins',
            'checkout_submodules'   => true,
        },
        'gdash/gdash'                    => {
            'upstream' => 'https://gerrit.wikimedia.org/r/operations/software/gdash',
        },
        'jobrunner/jobrunner'            => {
            'upstream'     => 'https://gerrit.wikimedia.org/r/mediawiki/services/jobrunner',
            'service_name' => 'jobrunner',
        },
        'grafana/grafana'                => {
            'upstream' => 'https://gerrit.wikimedia.org/r/operations/software/grafana',
        },
        'parsoid/deploy'                => {
            'upstream'              => 'https://gerrit.wikimedia.org/r/p/mediawiki/services/parsoid/deploy',
            'checkout_submodules'   => true,
            'service_name'          => 'parsoid',
        },
        'eventlogging/EventLogging'      => {
            'upstream' => 'https://gerrit.wikimedia.org/r/mediawiki/extensions/EventLogging',
        },
        'ocg/ocg' => {
            'upstream'              => 'https://gerrit.wikimedia.org/r/mediawiki/services/ocg-collection',
            'service_name'          => 'ocg',
            'checkout_submodules'   => true,
        },
        'mathoid/mathoid' => {
            'upstream'              => 'https://gerrit.wikimedia.org/r/mediawiki/services/mathoid',
            'service_name'          => 'mathoid',
            'checkout_submodules'   => true,
        },
        'citoid/deploy' => {
            'upstream'              => 'https://gerrit.wikimedia.org/r/mediawiki/services/citoid/deploy',
            'service_name'          => 'citoid',
            'checkout_submodules'   => true,
        },
        'rcstream/rcstream' => {
            'upstream'              => 'https://gerrit.wikimedia.org/r/mediawiki/services/rcstream',
            'service_name'          => 'rcstream',
        },
        'restbase/deploy' => {
            'upstream'              => 'https://gerrit.wikimedia.org/r/mediawiki/services/restbase/deploy',
            'service_name'          => 'restbase',
        },
        'fluoride/fluoride'              => {
            'upstream' => 'https://gerrit.wikimedia.org/r/mediawiki/tools/fluoride',
        },
        'mwprof/mwprof'                  => {
            'upstream' => 'https://gerrit.wikimedia.org/r/operations/software/mwprof',
        },
        'reporter/reporter'              => {
            'upstream' => 'https://gerrit.wikimedia.org/r/operations/software/mwprof/reporter',
        },
        'test/testrepo'                  => {
            'service_name'        => 'puppet',
            'checkout_submodules' => true,
        },
        'elasticsearch/plugins'          => {
            'gitfat_enabled' => true,
            'upstream'       => 'https://gerrit.wikimedia.org/r/operations/software/elasticsearch/plugins',
        },
        'analytics/refinery'        => {
            'gitfat_enabled'      => true,
            'upstream'            => 'https://gerrit.wikimedia.org/r/analytics/refinery',
        },
        'scholarships/scholarships'      => {
            'upstream' => 'https://gerrit.wikimedia.org/r/wikimedia/wikimania-scholarships',
        },
        'librenms/librenms'                  => {
            'upstream' => 'https://gerrit.wikimedia.org/r/operations/software/librenms',
        },
        'kibana/kibana'      => {
            'upstream' => 'https://gerrit.wikimedia.org/r/operations/software/kibana',
        },
        'scap/scap' => {
            'upstream' => 'https://gerrit.wikimedia.org/r/mediawiki/tools/scap',
        },
        'servermon/servermon'            => {
            'service_name' => 'servermon',
        },
        'iegreview/iegreview'      => {
            'grain'    => 'iegreview',
            'upstream' => 'https://gerrit.wikimedia.org/r/wikimedia/iegreview',
        },
    }
}

class role::deployment::salt_masters::production {
    $deployment_config = {
        'parent_dir' => '/srv/deployment',
        'servers'        => {
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

    class { '::keyholder':
        trusted_group => 'wikidev',
    }

    include ::keyholder::monitoring

    keyholder::private_key { 'mwdeploy_rsa':
        source => 'puppet:///private/ssh/tin/mwdeploy_rsa',
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
        dir       => '/srv/redis',
        maxmemory => '500Mb',
        monitor   => true,
    }

    package { 'percona-toolkit':
        ensure => latest,
    }

    sudo::group { 'wikidev_deployment_server':
        group      => 'wikidev',
        privileges => [
            'ALL = (root) NOPASSWD: /usr/bin/salt-call -l quiet --out=json pillar.data',
            'ALL = (root) NOPASSWD: /usr/bin/salt-call -l quiet publish.runner deploy.fetch *',
            'ALL = (root) NOPASSWD: /usr/bin/salt-call -l quiet publish.runner deploy.checkout *',
            'ALL = (root) NOPASSWD: /usr/bin/salt-call -l quiet --out=json publish.runner deploy.restart *',
        ],
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
        'servers'    => { 'eqiad'  => $deployment_server, },
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

    sudo::group { "project_${::instanceproject}_deployment_server":
        group      => "project-${::instanceproject}",
        privileges => [
            'ALL = (root) NOPASSWD: /usr/bin/salt-call -l quiet --out=json pillar.data',
            'ALL = (root) NOPASSWD: /usr/bin/salt-call -l quiet publish.runner deploy.fetch *',
            'ALL = (root) NOPASSWD: /usr/bin/salt-call -l quiet publish.runner deploy.checkout *',
            'ALL = (root) NOPASSWD: /usr/bin/salt-call -l quiet --out=json publish.runner deploy.restart *',
        ],
    }
}

class role::deployment::test {
    package { 'test/testrepo':
        provider => 'trebuchet',
    }
}
