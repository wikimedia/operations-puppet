# monitoring of git.wikimedia.org
class icinga::monitor::git {

    @monitoring::host { 'git.wikimedia.org':
        host_fqdn => 'git.wikimedia.org'
    }

    monitoring::service { 'git.wikimedia.org':
        description   => 'git.wikimedia.org',
        check_command => 'check_http_url!git.wikimedia.org!/tree/mediawiki%2Fvendor.git',
        host          => 'git.wikimedia.org',
        contact_group => 'admins',
    }

}
