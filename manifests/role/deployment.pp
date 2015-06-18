# Configuration info: https://wikitech.wikimedia.org/wiki/Trebuchet#Adding_a_new_repo
# Troubleshooting: https://wikitech.wikimedia.org/wiki/Trebuchet#Troubleshooting
class role::deployment::config {
    $repo_config = hiera_hash('repo_config')
}

class role::deployment::server(
    # Source of the key, change this if not in production, with hiera.
    $key_source = 'puppet:///private/ssh/tin/mwdeploy_rsa',
    $apache_fqdn = $::fqdn,
    $deployment_group = 'wikidev',
) {
    # Can't include this while scap is present on tin:
    # include misc::deployment::scripts

    class { 'deployment::deployment_server':
        deployer_groups => [$deployment_group],
    }

    # set umask for wikidev users so that newly-created files are g+w
    file { '/etc/profile.d/umask-wikidev.sh':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        source => 'puppet:///files/deploy/umask-wikidev-profile-d.sh',
    }

    include ::apache
    include ::apache::mod::dav
    include ::apache::mod::dav_fs
    include ::apache::helper_scripts

    include network::constants
    $deployable_networks = $::network::constants::deployable_networks

    include mediawiki
    include scap::master

    if $::realm != 'labs' {
        include wikitech::wiki::passwords
    }

    ferm::service { 'http_deployment_server':
        desc   => 'http on trebuchet deployment servers, for serving actual files to deploy',
        proto  => 'tcp',
        port   => '80',
        srange => $deployable_networks,
    }

    #T83854
    ::monitoring::icinga::git_merge { 'mediawiki_config':
        dir           => '/srv/mediawiki-staging/',
        user          => 'root',
        remote_branch => 'readonly/master'
    }

    class { '::keyholder': trusted_group => $deployment_group, } ->
    class { '::keyholder::monitoring': } ->
    keyholder::private_key { 'mwdeploy_rsa':
        source  => $key_source,
    }

    file { '/srv/deployment':
        ensure => directory,
        owner  => 'trebuchet',
        group  => $deployment_group,
    }

    apache::site { 'deployment':
        content => template('apache/sites/deployment.erb'),
        require => File['/srv/deployment'],
    }

    class { 'redis':
        dir       => '/srv/redis',
        maxmemory => '500Mb',
        monitor   => true,
    }

    ferm::service { 'deployment-redis':
        proto => 'tcp',
        port  => '6379',
    }

    sudo::group { "${deployment_group}_deployment_server":
        group      => $deployment_group,
        privileges => [
            'ALL = (root) NOPASSWD: /usr/bin/salt-call -l quiet --out=json pillar.data',
            'ALL = (root) NOPASSWD: /usr/bin/salt-call -l quiet publish.runner deploy.fetch *',
            'ALL = (root) NOPASSWD: /usr/bin/salt-call -l quiet publish.runner deploy.checkout *',
            'ALL = (root) NOPASSWD: /usr/bin/salt-call -l quiet --out=json publish.runner deploy.restart *',
        ],
    }

    package { 'percona-toolkit':
        ensure => latest,
    }

    # tig is a ncurses-based git utility which is useful for
    # determining the state of git repos during deployments.
    package { 'tig':
        ensure => latest,
    }
}

class role::deployment::salt_masters(
    $deployment_server = 'tin.eqiad.wmnet',
) {

    $deployment_config = {
        'parent_dir' => '/srv/deployment',
        'servers'    => {
            'eqiad'  => $deployment_server,
            'codfw'  => $deployment_server,
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

class role::deployment::test {
    package { 'test/testrepo':
        provider => 'trebuchet',
    }
}
