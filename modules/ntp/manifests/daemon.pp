# SPDX-License-Identifier: Apache-2.0
define ntp::daemon(
    Array[Stdlib::Host] $servers      = [],
    Array[Stdlib::Host] $pools        = [],
    Array[Stdlib::Host] $peers        = [],
    Array[Stdlib::Host] $query_acl    = [],
    Array[String]       $time_acl     = [],
    String              $extra_config = '',
    Wmflib::Ensure      $ensure       = lookup('ntp::daemon::ensure', {'default_value' => 'present'}),
){

    ensure_packages(['ntp'])

    file { 'ntp.conf':
        mode    => '0644',
        path    => '/etc/ntp.conf',
        content => template('ntp/ntp-conf.erb'),
    }

    service { 'ntp':
        ensure    => stdlib::ensure($ensure, 'service'),
        require   => [ File['ntp.conf'], Package['ntp'] ],
        subscribe => File['ntp.conf'],
    }
}
