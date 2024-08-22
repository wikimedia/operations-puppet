# SPDX-License-Identifier: Apache-2.0
class prometheus::nft_throttling_denylist (
    Wmflib::Ensure $ensure  = 'present',
) {
    $script = '/usr/local/bin/prometheus-nft-throttling-denylist.sh'

    file { $script:
        ensure => $ensure,
        mode   => '0555',
        owner  => 'root',
        group  => 'root',
        source => "puppet:///modules/prometheus${script}",
    }

    systemd::timer::job { 'prometheus-nft-throttling-denylist':
        ensure      => $ensure,
        user        => 'root',
        description => 'Generate nft throttling denylist length for the prometheus node exporter',
        command     => $script,
        interval    => {
            'start'    => 'OnCalendar',
            'interval' => 'minutely',
        },
        require     => [File[$script], Class['prometheus::node_exporter'],]
    }
}
