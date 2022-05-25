# SPDX-License-Identifier: Apache-2.0
# == Class: netconsole::server
# Configure a netconsole server reading messages from netconsole clients and
# printing them to standard output.
# See https://www.kernel.org/doc/Documentation/networking/netconsole.txt
#

class netconsole::server (
    Wmflib::Ensure $ensure = present,
    Stdlib::Port::User $port = 6666,
) {
    systemd::service { 'netconsole':
        ensure  => $ensure,
        content => systemd_template('netconsole'),
        restart => true,
        require => Package['netcat-openbsd'],
    }
}
