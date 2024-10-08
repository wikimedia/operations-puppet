# SPDX-License-Identifier: Apache-2.0
# == Class: profile::homer
#
# This class installs & manages Homer, a network configuration management tool.

class profile::homer (
    String $nb_ro_token = lookup('profile::netbox::ro_token'),
    Stdlib::HTTPSUrl $nb_api = lookup('netbox_api_url'),
    Optional[Stdlib::Host] $private_git_peer = lookup('profile::homer::private_git_peer'),
    Optional[String[1]] $diff_timer_interval = lookup('profile::homer::diff_timer_interval'),
    Optional[Boolean] $disable_homer = lookup('profile::homer::disable', {'default_value' => false}),
){

    unless $disable_homer {
        python_deploy::venv { 'homer': }

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

        if $disable_homer {
            $check_homer_diff_ensure = absent
        } else {
            $check_homer_diff_ensure = $diff_timer_interval  ? {
                undef   => absent,
                default => present,
            }
        }

        # If unset set a fixed value in the past just to pass validation by systemd-analyze calendar
        # as the timer will be absented in this case and interval is a required parameter.
        $effective_diff_timer_interval = pick($diff_timer_interval, '2021-01-01')

        systemd::timer::job { 'check-homer-diff':
            ensure      => $check_homer_diff_ensure,
            description => 'Check if any network device has a live config that differs from the code-defined one',
            command     => '/usr/local/sbin/check-homer-diff',
            interval    => {
                'start'    => 'OnCalendar',
                'interval' => $effective_diff_timer_interval,
            },
            user        => 'root',  # Needed to access the keyholder SSH key
            require     => File['/usr/local/sbin/check-homer-diff'],
        }
    }
}
