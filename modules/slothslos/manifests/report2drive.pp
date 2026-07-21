# SPDX-License-Identifier: Apache-2.0
##
# Class: slothslos::report2drive
#
# @summary
# Manage the `report2drive` runtime files and system user used by the
# reporting helper script.
#
# @description
# This class ensures a system user exists for running the `report2drive`
# helper, creates the configuration directory at `/etc/report2drive`, and
# deploys the `report2drive` executable to `/usr/local/bin`. It accepts a
# `user` parameter to control ownership and a flexible `ensure` parameter to
# allow removal or creation of the managed resources.
#
# @param user [String] Username to create for running `report2drive` and to
#   own created files and directories. Defaults to `'report2drive'`.
# @param ensure [Wmflib::Ensure, Optional] Desired resource state. When set
#   to `absent` this class will remove the managed files and directories;
#   when `present` (the default) the resources will be created.
#
class slothslos::report2drive (
    String $user = 'report2drive',
    Optional[Wmflib::Ensure] $ensure = present,
) {

    ensure_packages(['python3-google-auth', 'python3-googleapi', 'python3-wmflib', 'python3-click', 'python3-dateutil'])

    systemd::sysuser { $user: }

    file { '/etc/report2drive':
        ensure  => stdlib::ensure($ensure, 'directory'),
        owner   => $user,
        group   => $user,
        mode    => '0755',
        require => Systemd::Sysuser[$user],
    }

    file { '/usr/local/bin/report2drive':
        ensure => stdlib::ensure($ensure, 'file'),
        mode   => '0550',
        owner  => $user,
        source => 'puppet:///modules/slothslos/report2drive.py',
    }
}
