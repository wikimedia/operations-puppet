# vim: set sw=4 ts=4 expandtab:

# manifests/role/zuul.pp

# == Class: role::zuul::configuration
#
# Realm based configuration for Zuul roles.
class role::zuul::configuration {
    $zuul_git_dir = {
        'production' => '/srv/ssd/zuul/git',
        'labs'       => '/var/lib/zuul/git',
    }
} # /role::zuul::configuration

# == Class: role::zuul::labs
#
# Install the Zuul gating system suitable for the Continuous Integration labs
# instance. This role can not really be reused on a different instance since it
# hardcodes several parameters such as the Gerrit IP or the URL hostnames.
class role::zuul::labs {
    system_role { 'role::zuul::labs': description => 'Zuul on labs!' }

    include contint::proxy_zuul,
        role::zuul::configuration

    # Setup the instance for labs usage
    zuulwikimedia::instance { 'zuul-labs':
        jenkins_server   => 'http://10.4.0.172:8080/ci',
        jenkins_user     => 'zuul',
        gerrit_server    => '10.4.0.172',
        gerrit_user      => 'jenkins',
        url_pattern      => 'http://integration.wmflabs.org/ci/job/{job.name}/{build.number}/console',
        status_url       => 'http://integration.wmflabs.org/zuul/status',
        git_branch       => 'labs',
		git_dir          => $role::zuul::configuration::zuul_git_dir[$::realm],
        push_change_refs => false,
    }

} # /role::zuul::labs

# Class: role::zuul::production
#
# Install the continuous integration Zuul instance for production usage.
#
# https://www.mediawiki.org/wiki/Continuous_integration/Zuul
#
class role::zuul::production {
    system_role { 'role::zuul::production': description => 'Zuul on production' }

    # We will receive replication of git bare repositories from Gerrit
    include role::gerrit::production::replicationdest
    include contint::proxy_zuul

    file { '/var/lib/git':
        ensure => 'directory',
        owner  => 'gerritslave',
        group  => 'root',
        mode   => '0755',
    }

    # TODO: should require Mount['/srv/ssd']
    zuulwikimedia::instance { 'zuul-production':
        jenkins_server   => 'http://127.0.0.1:8080/ci',
        jenkins_user     => 'zuul-bot',
        gerrit_server    => 'manganese.wikimedia.org',
        gerrit_user      => 'jenkins-bot',
        url_pattern      => 'https://integration.wikimedia.org/ci/job/{job.name}/{build.number}/console',
        status_url       => 'https://integration.wikimedia.org/zuul/',
        git_branch       => 'master',
		git_dir          => $role::zuul::configuration::zuul_git_dir[$::realm],
        push_change_refs => false,
    }

} # /role::zuul::production
