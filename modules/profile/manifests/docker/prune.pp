# SPDX-License-Identifier: Apache-2.0
# Purge images on a weekly basis and dangling images daily
# to avoid filling up the disk
class profile::docker::prune(
    Wmflib::Ensure $ensure = lookup('docker::prune::ensure', { default_value => 'present' }),
) {
    systemd::timer::job { 'docker-system-prune-all':
        ensure      => $ensure,
        description => 'Prune all Docker images and volumes',
        user        => 'root',
        command     => '/usr/bin/docker system prune --all --volumes --force',
        splay       => 3600,  # seconds
        interval    => {
            'start'    => 'OnCalendar',
            'interval' => 'Sunday 3:00 UTC',
        },
    }

    systemd::timer::job { 'docker-system-prune-dangling':
        ensure      => $ensure,
        description => 'Prune dangling Docker images',
        user        => 'root',
        command     => '/usr/bin/docker system prune --force',
        splay       => 3600,  # seconds
        interval    => {
            'start'    => 'OnCalendar',
            'interval' => 'Mon-Sat 3:00 UTC',
        },
    }
}
