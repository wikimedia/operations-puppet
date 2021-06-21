# a placeholder profile for a manual gitlab setup by
# https://phabricator.wikimedia.org/T274458
class profile::gitlab(
    Stdlib::IP::Address::V4 $service_ip_v4 = lookup('profile::gitlab::service_ip_v4'),
    Stdlib::IP::Address::V6 $service_ip_v6 = lookup('profile::gitlab::service_ip_v6'),
    Stdlib::Unixpath $backup_dir_data = lookup('profile::gitlab::backup_dir_data'),
    Stdlib::Unixpath $backup_dir_config = lookup('profile::gitlab::backup_dir_config'),
){

    $acme_chief_cert = 'gitlab'

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
}
