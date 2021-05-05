# == Class: profile::homer
#
# This class installs & manages Homer, a network configuration management tool.

class profile::homer (
    Stdlib::Host $private_git_peer = lookup('profile::homer::private_git_peer'),
    String $nb_ro_token = lookup('profile::netbox::tokens::read_only'),
    Stdlib::HTTPSUrl $nb_api = lookup('profile::netbox::netbox_api'),
    String $diff_timer_interval = lookup('profile::homer::diff_timer_interval'),
){

    ensure_packages(['virtualenv', 'make'])

    # Only use scap up to Buster, deployment will switch to a cookbook
    if debian::codename::le('buster') {
        scap::target { 'homer/deploy':
            deploy_user => 'deploy-homer',
        }
    } else {
        class { 'python_deploy::venv':
            project_name => 'homer',
            deploy_user  => 'deploy-homer',
        }
    }

    keyholder::agent { 'homer':
        trusted_groups => ['ops', 'root'],
    }

    class { 'homer':
        private_git_peer => $private_git_peer,
        nb_token         => $nb_ro_token,
        nb_api           => $nb_api,
    }

    file { '/usr/local/sbin/check-homer-diff':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0544',
        source  => 'puppet:///modules/profile/homer/check_homer_diff.sh',
        require => Class['homer'],
    }

    systemd::timer::job { 'check-homer-diff':
        description => 'Check if any network device has a live config that differs from the code-defined one',
        command     => '/usr/local/sbin/check-homer-diff',
        interval    => {
            'start'    => 'OnCalendar',
            'interval' => $diff_timer_interval,
        },
        user        => 'root',  # Needed to access the keyholder SSH key
        require     => File['/usr/local/sbin/check-homer-diff'],
    }
}
