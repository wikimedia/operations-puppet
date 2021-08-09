# a placeholder profile for a manual gitlab setup by
# https://phabricator.wikimedia.org/T274458
class profile::gitlab(
    Stdlib::Fqdn $active_host = lookup('profile::gitlab::active_host'),
    Stdlib::Fqdn $passive_host = lookup('profile::gitlab::passive_host'),
    Wmflib::Ensure $backup_sync_ensure = lookup('profile::gitlab::backup_sync::ensure'),
    Stdlib::IP::Address::V4 $service_ip_v4 = lookup('profile::gitlab::service_ip_v4'),
    Stdlib::IP::Address::V6 $service_ip_v6 = lookup('profile::gitlab::service_ip_v6'),
    Stdlib::Unixpath $backup_dir_data = lookup('profile::gitlab::backup_dir_data'),
    Stdlib::Unixpath $backup_dir_config = lookup('profile::gitlab::backup_dir_config'),
    Array[Stdlib::Host] $prometheus_nodes = lookup('prometheus_nodes', {default_value => []}),
){

    $acme_chief_cert = 'gitlab'

    if $active_host == $facts['fqdn'] {
        # Bacula backups, also see profile::backup::filesets (T274463)
        backup::set { 'gitlab':
            jobdefaults => 'Daily-production',  # full backups every day
        }
    }

    exec {'Reload nginx':
      command     => '/usr/bin/gitlab-ctl hup nginx',
      refreshonly => true,
    }

    # Certificates will be available under:
    # /etc/acmecerts/<%= @acme_chief_cert %>/live/
    acme_chief::cert { $acme_chief_cert:
        puppet_rsc => Exec['Reload nginx'],
    }
    apt::package_from_component{'gitlab-ce':
        component => 'thirdparty/gitlab',
    }

    # add a service IP to the NIC - T276148
    interface::alias { 'gitlab service IP':
        ipv4 => $service_ip_v4,
        ipv6 => $service_ip_v6,
    }

    # open ports in firewall - T276144

    # world -> service IP, HTTP
    ferm::service { 'gitlab-http-public':
        proto  => 'tcp',
        port   => 80,
        drange => "(${service_ip_v4} ${service_ip_v6})",
    }

    # world -> service IP, HTTPS
    ferm::service { 'gitlab-https-public':
        proto  => 'tcp',
        port   => 443,
        drange => "(${service_ip_v4} ${service_ip_v6})",
    }

    # world -> service IP, SSH
    ferm::service { 'gitlab-ssh-public':
        proto  => 'tcp',
        port   => 22,
        drange => "(${service_ip_v4} ${service_ip_v6})",
    }
    # Theses parameters are installed by gitlab when the package is updated
    # However we purge this directory in puppet as such we need to add them here
    # TODO: Ensure theses values actually make sense
    sysctl::parameters {'omnibus-gitlab':
        priority => 90,
        values   => {
            'kernel.sem'         => '250 32000 32 262',
            'kernel.shmall'      => 4194304,
            'kernel.shmmax'      => 17179869184,
            'net.core.somaxconn' => 1024,
        },
    }

    wmflib::dir::mkdir_p("${backup_dir_data}/latest", {
        owner => 'root',
        group => 'root',
        mode  => '0600',
    })

    wmflib::dir::mkdir_p("${backup_dir_config}/latest", {
        owner => 'root',
        group => 'root',
        mode  => '0600',
    })

    if !empty($prometheus_nodes) {
        # gitlab exports metrics on multiple ports and prometheus nodes need access
        $prometheus_ferm_nodes = join($prometheus_nodes, ' ')
        $ferm_srange = "(@resolve((${prometheus_ferm_nodes})) @resolve((${prometheus_ferm_nodes}), AAAA))"

        ferm::service { 'gitlab_nginx':
            proto  => 'tcp',
            port   => '8060',
            srange => $ferm_srange,
        }

        ferm::service { 'gitlab_redis':
            proto  => 'tcp',
            port   => '9121',
            srange => $ferm_srange,
        }

        ferm::service { 'gitlab_postgres':
            proto  => 'tcp',
            port   => '9187',
            srange => $ferm_srange,
        }

        ferm::service { 'gitlab_workhorse':
            proto  => 'tcp',
            port   => '9229',
            srange => $ferm_srange,
        }

        ferm::service { 'gitlab_rails':
            proto  => 'tcp',
            port   => '8083',
            srange => $ferm_srange,
        }

        ferm::service { 'gitlab_sidekiq':
            proto  => 'tcp',
            port   => '8082',
            srange => $ferm_srange,
        }

        ferm::service { 'gitlab_server':
            proto  => 'tcp',
            port   => '9168',
            srange => $ferm_srange,
        }

        ferm::service { 'gitlab_gitaly':
            proto  => 'tcp',
            port   => '9236',
            srange => $ferm_srange,
        }
    }

    # JSON Logs
    rsyslog::input::file { 'gitlab-gitaly-json':
      path => '/var/log/gitlab/gitaly/current',
    }

    rsyslog::input::file { 'gitlab-rails-production-json':
      path => '/var/log/gitlab/gitlab-rails/production_json.log',
    }

    rsyslog::input::file { 'gitlab-rails-api-json':
      path => '/var/log/gitlab/gitlab-rails/api_json.log',
    }

    rsyslog::input::file { 'gitlab-rails-application-json':
      path => '/var/log/gitlab/gitlab-rails/application_json.log',
    }

    rsyslog::input::file { 'gitlab-rails-exceptions-json':
      path => '/var/log/gitlab/gitlab-rails/exceptions_json.log',
    }

    rsyslog::input::file { 'gitlab-workhorse-json':
      path => '/var/log/gitlab/gitlab-workhorse/current',
    }

    rsyslog::input::file { 'gitlab-sidekiq-json':
      path => '/var/log/gitlab/sidekiq/current',
    }

    # @cee Json Logs
    rsyslog::input::file { 'gitlab-nginx-access-cee':
      path => '/var/log/gitlab/nginx/gitlab_access.log',
    }

    # Plain logs
    rsyslog::input::file { 'gitlab-nginx-error-plain':
      path => '/var/log/gitlab/nginx/gitlab_error.log',
    }

    rsyslog::input::file { 'gitlab-redis-plain':
      path => '/var/log/gitlab/redis/current',
    }

    # TODO T274462
    # rsyslog::input::file { 'gitlab-postgres':
    #   path => '/var/log/gitlab/postgresql/current',
    # }

    # T285867 sync active and passive GitLab server backups
    class { 'rsync::server': }
    class { 'gitlab::rsync':
        active_host  => $active_host,
        passive_host => $passive_host,
        ensure       => $backup_sync_ensure
    }
}
