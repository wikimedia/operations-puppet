# == Class: netconsole::server
# Configure a netconsole server reading messages from netconsole clients and
# printing them to standard output.
# See https://www.kernel.org/doc/Documentation/networking/netconsole.txt
#

class netconsole::server (
    Wmflib::Ensure $ensure = present,
    Wmflib::UserIpPort $port = 6666,
) {
    package { 'netcat-openbsd':
        ensure => present,
    }

    systemd::service { 'netconsole':
        ensure  => $ensure,
        content => systemd_template('netconsole'),
        restart => true,
        require => Package['netcat-openbsd'],
    }
}
