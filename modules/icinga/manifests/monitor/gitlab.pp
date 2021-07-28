# = Class: icinga::monitor::gitlab
#
# Monitor Gitlab (T275170)
class icinga::monitor::gitlab {

    @monitoring::host { 'gitlab.wikimedia.org':
        host_fqdn => 'gitlab.wikimedia.org',
    }

    monitoring::service { 'gitlab-https':
        description   => 'Gitlab HTTPS healthcheck',
        check_command => 'check_https_url!gitlab.wikimedia.org!/explore',
        host          => 'gitlab.wikimedia.org',
        notes_url     => 'https://wikitech.wikimedia.org/wiki/GitLab#Monitoring',
    }

    monitoring::service { 'gitlab-ssh':
        description   => 'Gitlab SSH healthcheck git daemon',
        check_command => 'check_ssh_port_ip!22!gitlab.wikimedia.org',
        host          => 'gitlab.wikimedia.org',
        notes_url     => 'https://wikitech.wikimedia.org/wiki/GitLab#Monitoring',
    }
}
