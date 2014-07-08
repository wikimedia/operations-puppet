# manifests/zuul.pp

class zuulwikimedia {

    # Deploy wikimedia Zuul configuration files
    # Parameters are passed to the files templates
    define instance(
        $jenkins_server,
        $jenkins_user,
        $gearman_server,
        $gearman_server_start,
        $gerrit_server,
        $gerrit_user,
        $url_pattern,
        $status_url,
        $zuul_url,
        $config_git_branch='master',
        $git_dir='/var/lib/zuul/git',
        $statsd_host = '',
        $git_email = "zuul-merger@${::hostname}",
        $git_name = 'Wikimedia Zuul Merger'
    ) {

        # Zuul server needs an API key to interact with Jenkins:
        require passwords::misc::contint::jenkins
        $jenkins_apikey = $::passwords::misc::contint::jenkins::zuul_user_apikey

        class { '::zuul::server':
            statsd_host          => $statsd_host,
            gerrit_server        => $gerrit_server,
            gerrit_user          => $gerrit_user,
            jenkins_server       => $jenkins_server,
            jenkins_user         => $jenkins_user,
            jenkins_apikey       => $jenkins_apikey,
            gearman_server       => $gearman_server,
            gearman_server_start => $gearman_server_start,
            url_pattern          => $url_pattern,
            status_url           => $status_url,
            zuul_url             => $zuul_url,
        }
        include zuul::monitoring::server

        class { '::zuul::merger':
            gearman_server => $gearman_server,
            gerrit_server  => $gerrit_server,
            gerrit_user    => $gerrit_user,
            git_dir        => $git_dir,
            git_email      => "zuul-merger@${::hostname}",
            git_name       => 'Wikimedia Zuul Merger',
            url_pattern    => $url_pattern,
            status_url     => $status_url,
            zuul_url       => $zuul_url,
        }

        # Deploy Wikimedia Zuul configuration files.
        #
        # Describe the behaviors and jobs
        # Conf file is hosted in integration/zuul-config git repo
        git::clone {
            'integration/zuul-config':
                directory => '/etc/zuul/wikimedia',
                owner     => jenkins,
                group     => jenkins,
                mode      => '0775',
                origin    => 'https://gerrit.wikimedia.org/r/p/integration/zuul-config.git',
                branch    => $config_git_branch,
        }
    }
}
