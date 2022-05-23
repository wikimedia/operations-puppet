# SPDX-License-Identifier: Apache-2.0
# Systemd fails to start/cleanup session scope under load, periodically cleanup as a bandaid.
# See also https://phabricator.wikimedia.org/T199911

class toil::systemd_scope_cleanup (
    Wmflib::Ensure $ensure = 'present',
) {
    $minute = fqdn_rand(59, "toil_${title}")

    systemd::timer::job { 'systemd_scope_cleanup':
        ensure      => $ensure,
        description => 'Regular jobs to cleanup systemd session scope',
        user        => 'root',
        command     => '/bin/systemctl reset-failed \*.scope',
        interval    => {'start' => 'OnCalendar', 'interval' => "*-*-* *:${minute}:00"},
    }
}
