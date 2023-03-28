# SPDX-License-Identifier: Apache-2.0
# @summary Alternative to profile::docker::prune. Prunes only old images
# @param ensure
#    Can be provided to control the "ensure" attribute of created resources.
#
# @param older_than
#    Specifies the minimum age for an image to be a candidate for pruning. In days.
class profile::docker::prune_old_images(
    Wmflib::Ensure $ensure = lookup('docker::prune_old_images::ensure', { default_value => 'present' }),
    Integer[1] $older_than = lookup('docker::prune_old_images::older_than', { default_value => 14 }),
) {
    systemd::timer::job { 'docker-image-prune-old':
        ensure      => $ensure,
        description => 'Prune old Docker images',
        user        => 'root',
        command     => "/usr/bin/docker image prune --all --force --filter until=${$older_than * 24}h",
        interval    => {
            'start'    => 'OnCalendar',
            'interval' => '*-*-* 1:00 UTC',
        },
    }
}
