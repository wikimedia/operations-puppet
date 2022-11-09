# SPDX-License-Identifier: Apache-2.0

# A bandaid for ifupdown race on boot.
# See also https://phabricator.wikimedia.org/T273026

class toil::ganeti_ifupdown (
    Wmflib::Ensure $ensure = present,
) {
    systemd::timer::job { 'ganeti-ifupdown-bandaid':
        ensure          => $ensure,
        interval        => {
            'start'    => 'OnBootSec',
            'interval' => '2min',
        },
        user            => 'root',
        logging_enabled => false,
        command         => '/bin/systemctl reset-failed ifup@*',
        description     => 'Bandaid for ifupdown race. T273026',
    }
}
