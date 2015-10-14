# Configuration info: https://wikitech.wikimedia.org/wiki/Trebuchet#Adding_a_new_repo
# Troubleshooting: https://wikitech.wikimedia.org/wiki/Trebuchet#Troubleshooting
class role::deployment::config {
    $repo_config = hiera_hash('role::deployment::repo_config')
}

class role::deployment::server(
    $apache_fqdn = $::fqdn,
    $deployment_group = 'wikidev',
) {
    # Can't include this while scap is present on tin:
    # include misc::deployment::scripts
    include role::deployment::mediawiki
    include role::deployment::services

    class { 'deployment::deployment_server':
        deployer_groups => [$deployment_group],
    }

    # set umask for wikidev users so that newly-created files are g+w
    file { '/etc/profile.d/umask-wikidev.sh':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        # NOTE: This file is also used in role::statistics
        source => 'puppet:///files/deploy/umask-wikidev-profile-d.sh',
    }

    include ::apache
    include ::apache::mod::dav
    include ::apache::mod::dav_fs
    include ::apache::helper_scripts
    include mysql

    include network::constants
    $deployable_networks = $::network::constants::deployable_networks

    include mediawiki
    include ::mediawiki::nutcracker
    include scap::master

    ferm::service { 'rsyncd_scap_master':
        proto   => 'tcp',
        port    => '873',
        srange  => '$MW_APPSERVER_NETWORKS',
    }

    if $::realm != 'labs' {
        include role::releases::upload
        include wikitech::wiki::passwords
    }

    $deployable_networks_ferm = join($deployable_networks, ' ')

    # T113351
    ferm::service { 'http_deployment_server':
        desc   => 'http on trebuchet deployment servers, for serving actual files to deploy',
        proto  => 'tcp',
        port   => '80',
        srange => "(${deployable_networks_ferm})",
    }

    # T115075
    ferm::service { 'ssh_deployment_server_ipv4':
        ensure => present,
        rule   => 'proto tcp dport ssh saddr $DEPLOYMENT_HOSTS ACCEPT;',
    }

    #T83854
    ::monitoring::icinga::git_merge { 'mediawiki_config':
        dir           => '/srv/mediawiki-staging/',
        user          => 'root',
        remote_branch => 'readonly/master'
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

    if $::realm != 'labs' {
        # backup /home dirs on deployment servers
        include role::backup::host
        backup::set {'home': }
    }

    # jq is a cli program for manipulating json (from api endpoints and such)
    ensure_packages(['jq'])
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

class role::deployment::mediawiki(
    $keyholder_user = 'mwdeploy',
    $keyholder_group = 'wikidev',
    $key_fingerprint = 'f5:18:a3:44:77:a2:31:23:cb:7b:44:e1:4b:45:27:11',
) {
    require ::keyholder
    require ::keyholder::monitoring

    keyholder::agent { $keyholder_user:
        trusted_group   => $keyholder_group,
        key_fingerprint => $key_fingerprint,
    }
}

class role::deployment::services (
    $keyholder_user  = 'deploy-service',
    $keyholder_group = 'deploy-service',
    $key_fingerprint  = '6d:54:92:8b:39:10:f5:9b:84:40:36:ef:3c:9a:6d:d8',
) {
    require ::keyholder
    require ::keyholder::monitoring

    keyholder::agent { $keyholder_user:
        trusted_group   => $keyholder_group,
        key_fingerprint => $key_fingerprint,
        key_file        => 'servicedeploy_rsa',
    }
}

class role::deployment::test {
    package { 'test/testrepo':
        provider => 'trebuchet',
    }
}
