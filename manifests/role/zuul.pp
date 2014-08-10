# vim: set sw=4 ts=4 expandtab:

# manifests/role/zuul.pp

# == Class: role::zuul::configuration
#
# Realm based configuration for Zuul roles.
class role::zuul::configuration {

    $shared = {
        'production' => {
            'gearman_server'    => '208.80.154.135',  # gallium.wikimedia.org
            'git_source_branch' => 'master',
            'gerrit_server'     => 'ytterbium.wikimedia.org',
            'gerrit_user'       => 'jenkins-bot',
            'url_pattern'       => 'https://integration.wikimedia.org/ci/job/{job.name}/{build.number}/console',
            'status_url'        => 'https://integration.wikimedia.org/zuul/',
        },
        'labs' => {
            'gearman_server'       => '127.0.0.1',
            'git_source_branch' => 'labs',
            'gerrit_server'     => '127.0.0.1',
            'gerrit_user'       => 'jenkins',
            'url_pattern'       => 'http://integration.wmflabs.org/ci/job/{job.name}/{build.number}/console',
            'status_url'        => 'http://integration.wmflabs.org/zuul/status',
        },
    }

    $merger = {
        'production' => {
            'git_dir'   => '/srv/ssd/zuul/git',
            'git_email' => "zuul-merger@${::hostname}",
            'git_name'  => 'Wikimedia Zuul Merger',
            # FIXME should be $::fqdn
            'zuul_url'  => 'git://zuul.eqiad.wmnet',
        },
        'labs' => {
            # FIXME migrate under /data/project whenever bug 64868 is solved
            #   'git_dir'       => '/data/project/zuul/git',
            'git_dir' => '/srv/zuul/git',
            'git_email' => "zuul-merger@${::hostname}",
            'git_name'  => 'Wikimedia Zuul Merger',
            # FIXME should be $::fqdn
            'zuul_url'  => 'git://localhost',
        },
    }

    $server = {
        'production' => {
            'config_git_branch'    => 'master',
            'gearman_server_start' => true,
            'jenkins_server'       => 'http://127.0.0.1:8080/ci',
            'jenkins_user'         => 'zuul-bot',
            'statsd_host'          => 'statsd.eqiad.wmnet',
        },
        'labs' => {
            'config_git_branch'    => 'labs',
            'gearman_server_start' => true,
            'jenkins_server'       => 'http://127.0.0.1:8080/ci',
            'jenkins_user'         => 'zuul',
            'statsd_host'          => '',
        },
    }

} # /role::zuul::configuration

# == Class role::zuul::install
#
# Wrapper around ::zuul class which is needed by both merger and server roles
# that can in turn be installed on the same node. Prevent a duplication error.
#
class role::zuul::install {

    include role::zuul::configuration

    class { '::zuul':
        git_source_branch => $role::zuul::configuration::shared[$::realm]['git_source_branch'],
    }
} # /role::zuul::install

class role::zuul::server {
    system::role { 'role::zuul::server': description => 'Zuul server (scheduler)' }

    include contint::proxy_zuul
    include role::zuul::configuration
    include role::zuul::install
    include ::zuul::monitoring::server

    # Zuul server needs an API key to interact with Jenkins:
    require passwords::misc::contint::jenkins
    $jenkins_apikey = $::passwords::misc::contint::jenkins::zuul_user_apikey

    class { '::zuul::server':
        # Shared settings
        gearman_server       => $role::zuul::configuration::shared[$::realm]['gearman_server'],
        gerrit_server        => $role::zuul::configuration::shared[$::realm]['gerrit_server'],
        gerrit_user          => $role::zuul::configuration::shared[$::realm]['gerrit_user'],
        url_pattern          => $role::zuul::configuration::shared[$::realm]['url_pattern'],
        status_url           => $role::zuul::configuration::shared[$::realm]['status_url'],

        # Server settings
        gearman_server_start => $role::zuul::configuration::server[$::realm]['gearman_server_start'],
        jenkins_apikey       => $jenkins_apikey,
        jenkins_server       => $role::zuul::configuration::server[$::realm]['jenkins_server'],
        jenkins_user         => $role::zuul::configuration::server[$::realm]['jenkins_user'],
        statsd_host          => $role::zuul::configuration::server[$::realm]['statsd_host'],
    }

    # Deploy Wikimedia Zuul configuration files.
    #
    # Describe the behaviors and jobs
    # Conf file is hosted in integration/zuul-config git repo
    git::clone { 'integration/zuul-config':
        directory => '/etc/zuul/wikimedia',
        owner     => zuul,
        group     => zuul,
        mode      => '0775',
        origin    => 'https://gerrit.wikimedia.org/r/p/integration/zuul-config.git',
        branch    => $role::zuul::configuration::server[$::realm]['config_git_branch'],
    }

} # /role::zuul::server

class role::zuul::merger {
    system::role { 'role::zuul::merger': description => 'Zuul merger' }

    if $::realm == 'production' {
        # We will receive replication of git bare repositories from Gerrit
        include role::gerrit::production::replicationdest
    }

    include role::zuul::configuration
    include role::zuul::install
    include ::zuul::monitoring::merger

    class { '::zuul::merger':
        # Shared settings
        gearman_server       => $role::zuul::configuration::shared[$::realm]['gearman_server'],
        gerrit_server        => $role::zuul::configuration::shared[$::realm]['gerrit_server'],
        gerrit_user          => $role::zuul::configuration::shared[$::realm]['gerrit_user'],
        url_pattern          => $role::zuul::configuration::shared[$::realm]['url_pattern'],
        status_url           => $role::zuul::configuration::shared[$::realm]['status_url'],

        # Merger related
        git_dir              => $role::zuul::configuration::merger[$::realm]['git_dir'],
        git_email            => $role::zuul::configuration::merger[$::realm]['git_email'],
        git_name             => $role::zuul::configuration::merger[$::realm]['git_name'],
        zuul_url             => $role::zuul::configuration::merger[$::realm]['zuul_url'],
    }

    # Serves Zuul git repositories
    class { 'contint::zuul::git-daemon':
        zuul_git_dir => $role::zuul::configuration::merger[$::realm]['git_dir'],
    }

} # /role::zuul::merger


# == Class: role::zuul::labs
#
# Install the Zuul gating system suitable for the Continuous Integration labs
# instance. This role can not really be reused on a different instance since it
# hardcodes several parameters such as the Gerrit IP or the URL hostnames.
#
# For back compatibility purposes
class role::zuul::labs {
    system::role { 'role::zuul::labs (obsolete)': description => 'Zuul on labs!' }

    include role::zuul::merger
    include role::zuul::server

} # /role::zuul::labs

# Class: role::zuul::production
#
# Install the continuous integration Zuul instance for production usage.
#
# https://www.mediawiki.org/wiki/Continuous_integration/Zuul
#
# The Zuul git repositories are published over the git:// protocol by using git
# daemon. That allows remote Jenkins slaves to fetch the references crafted by
# Zuul when a change is submitted.
#
class role::zuul::production {
    system::role { 'role::zuul::production (obsolete)': description => 'Zuul on production' }

    include role::zuul::merger
    include role::zuul::server

} # /role::zuul::production
