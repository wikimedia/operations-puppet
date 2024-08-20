# SPDX-License-Identifier: Apache-2.0
# @summary profile to configure varnish frontend text nodes
# @param esitest_ensure ensureable parameter for esitest
class profile::cache::varnish::frontend::text (
    Wmflib::Ensure $esitest_ensure = lookup('profile::cache::varnish::frontend::text::esitest_ensure', {'default_value' => 'absent'}),
) {
    # for VCL compilation using libGeoIP
    class { 'geoip': }
    class { 'geoip::dev': }

    # Include ESI testing backend service in all text nodes
    class { 'esitest':
        ensure     => $esitest_ensure,
        numa_iface => $facts['interface_primary'],
    }

    # differential privacy support: T315676
    # for VCL compilation using libsodium
    ensure_packages(['libsodium-dev'])

    # script used to generate a daily key
    ensure_packages(['python3-nacl', 'python3-pystemd']) # python dependencies
    $dp_generator_path = '/usr/local/sbin/varnish-dp-key-generator'
    file { $dp_generator_path:
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/profile/cache/varnish_dp_key_generator.py',
    }

    # master key
    $master_key_path = '/etc/varnish/dp.master.key'
    $sub_key_path = '/etc/varnish/dp.daily.key'
    file { $master_key_path:
        ensure    => present,
        owner     => 'root',
        group     => 'root',
        mode      => '0600',
        show_diff => false,
        backup    => false,
        content   => wmflib::secret('varnish/dp.master.key', true),
    }

    # provide an initial sub key file
    exec { "${dp_generator_path} ${master_key_path} ${sub_key_path}":
        creates => $sub_key_path,
        require => Package['python3-nacl'],
    }

    $minute = fqdn_rand(30, 'dp-key-refresh')

    systemd::timer::job { 'refresh-dp-key':
        ensure            => present,
        description       => 'Refresh DP key used by varnish daily',
        user              => 'root',
        command           => "${dp_generator_path} ${master_key_path} ${sub_key_path}",
        syslog_identifier => 'timer-refresh-dp-key',
        interval          => {
            'start'    => 'OnCalendar',
            'interval' => "*-*-* 00:${minute}:00"
        },
    }
}
