#  == Class systemd::config ==
#
# Ship systemd global configuration file /etc/systemd/system.conf. See
# systemd-system.conf(5)
#

class systemd::config (
    Wmflib::Ensure $ensure = present,
    Stdlib::Yes_no $cpu_accounting = 'no',
    Stdlib::Yes_no $blockio_accounting = 'no',
    Stdlib::Yes_no $memory_accounting = 'no',
    Stdlib::Yes_no $ip_accounting = 'no',
){
    file { '/etc/systemd/system.conf':
        ensure  => $ensure,
        content => template('systemd/system.conf.erb'),
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
    }
}
