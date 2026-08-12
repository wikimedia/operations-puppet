# SPDX-License-Identifier: Apache-2.0
# @summary Install and configure tofurkey, a tool for distributed sync of Linux TCP Fast Open key rotations.
# @param $enabled
# @param $secret shared secret for all hosts in the same cluster.
# @param $rotation_interval Interval seconds for key rotation. Intervals *must* match across a cluster to get the same keys!
class tofurkey (
    Boolean                         $enabled,
    Optional[String]                $keyfile,
    Integer[10,604800]              $rotation_interval
) {
    ensure_packages(['tofurkey'])

    $enable_tuforkey = $enabled and ($keyfile != undef)
    $service_name = 'tofurkey'
    $keyfile_path = '/etc/tofurkey/keyfile'

    file { '/etc/tofurkey':
        ensure => $enable_tuforkey.bool2str('directory', 'absent')
    }

    file { $keyfile_path:
        ensure    => $enable_tuforkey.bool2str('file', 'absent'),
        mode      => '0400',
        content   => wmflib::secret("tofurkey/${keyfile}", true),
        show_diff => false,
        backup    => false,
        notify    => Service['tofurkey']
    }

    systemd::mask { 'mask_default_tofurkey':
        unit => 'tofurkey.service',
    }

    systemd::service { $service_name:
        ensure  => $enable_tuforkey.bool2str('present', 'absent'),
        content => systemd_template('tofurkey@'),
        restart => true,
    }


    profile::auto_restarts::service { $service_name:
        ensure => $enable_tuforkey.bool2str('present', 'absent')
    }

    if $enabled and ($keyfile == undef) {
        fail('TCP Fast Open key rotation enabled, but no keyfile is defined!')
    }
}
