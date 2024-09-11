# SPDX-License-Identifier: Apache-2.0
define ntp::daemon(
    Array[Stdlib::Host] $servers      = [],
    Array[Stdlib::Host] $pools        = [],
    Array[Stdlib::Host] $query_acl    = [],
    Array[String]       $time_acl     = [],
    String              $extra_config = '',
    Wmflib::Ensure      $ensure       = lookup('ntp::daemon::ensure', {'default_value' => 'present'}),
){

    # Debian bookworm and above use ntpsec and alias the ntp service but be
    # explicit here so that we know what we are running in production.
    ensure_packages(['ntpsec'])

    file { 'ntpsec.conf':
        mode    => '0644',
        path    => '/etc/ntpsec/ntp.conf',
        content => template('ntp/ntp-conf.erb'),
    }

    service { 'ntpsec':
        ensure  => stdlib::ensure($ensure, 'service'),
        require => [ File['ntpsec.conf'], Package['ntpsec'] ],
    }
}
