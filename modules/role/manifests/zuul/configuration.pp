# == Class: role::zuul::configuration
#
# Realm based configuration for Zuul roles.
class role::zuul::configuration {

    $shared = {
        'production' => {
            'gerrit_server'       => 'lead.wikimedia.org',
            'gerrit_user'         => 'jenkins-bot',
            'url_pattern'         => 'https://integration.wikimedia.org/ci/job/{job.name}/{build.number}/console',
            'status_url'          => 'https://integration.wikimedia.org/zuul/',
        },
        'labs' => {
            'gerrit_server'       => '127.0.0.1',
            'gerrit_user'         => 'jenkins',
            'url_pattern'         => 'http://integration.wmflabs.org/ci/job/{job.name}/{build.number}/console',
            'status_url'          => 'http://integration.wmflabs.org/zuul/status',
        },
    }

    $merger = {
        'production' => {
            'gearman_server'      => '208.80.154.135',  # gallium.wikimedia.org
            'gerrit_ssh_key_file' => 'ssh/ci/jenkins-bot_gerrit_id_rsa',
            'git_dir'             => '/srv/ssd/zuul/git',
            'git_email'           => "zuul-merger@${::hostname}",
            'git_name'            => 'Wikimedia Zuul Merger',
            'zuul_url'            => "git://${::fqdn}",
        },
        'labs' => {
            'gearman_server'      => '127.0.0.1',
            'gerrit_ssh_key_file' => 'ssh/ci/jenkins-bot_gerrit_id_rsa',
            # FIXME migrate under /data/project whenever T66868 is solved
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
            'gearman_server'       => '127.0.0.1',  # ferm default to accept on loopback
            'config_git_branch'    => 'master',
            'gearman_server_start' => true,
            'jenkins_server'       => 'http://127.0.0.1:8080/ci',
            'jenkins_user'         => 'zuul-bot',
            'statsd_host'          => 'statsd.eqiad.wmnet',
        },
        'labs' => {
            'gearman_server'       => '127.0.0.1',
            'config_git_branch'    => 'labs',
            'gearman_server_start' => true,
            'jenkins_server'       => 'http://127.0.0.1:8080/ci',
            'jenkins_user'         => 'zuul',
            'statsd_host'          => '',
        },
    }

}
