# = Class: icinga::monitor::gitlab
#
# Monitor Gitlab (T275170)
class icinga::monitor::gitlab {

    @monitoring::host { 'gitlab.wikimedia.org':
        host_fqdn => 'gitlab.wikimedia.org',
    }

    @monitoring::host { 'gitlab-replica-a.wikimedia.org':
        host_fqdn => 'gitlab-replica-a.wikimedia.org',
    }

    @monitoring::host { 'gitlab-replica-b.wikimedia.org':
        host_fqdn => 'gitlab-replica-b.wikimedia.org',
    }

    monitoring::service {
        default:
            host           => 'gitlab.wikimedia.org',
            notes_url      => 'https://wikitech.wikimedia.org/wiki/GitLab#Monitoring',
            migration_task => 'T384922';
        'gitlab-https':
            description   => 'Gitlab HTTPS healthcheck',
            check_command => 'check_https_url!gitlab.wikimedia.org!/explore';
        'gitlab-https-expiry':
            description   => 'Gitlab HTTPS SSL Expiry',
            check_command => 'check_https_expiry!gitlab.wikimedia.org!443';
        'gitlab-ssh':
            # SSH is not behind the CDN: the public name resolves to text-lb, which
            # only serves HTTPS, so probe the dedicated SSH hostname instead.
            description   => 'Gitlab SSH healthcheck git daemon',
            check_command => 'check_ssh_port_ip!22!gitlab-ssh.wikimedia.org';
    }
}
