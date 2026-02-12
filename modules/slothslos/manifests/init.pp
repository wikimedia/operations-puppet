# SPDX-License-Identifier: Apache-2.0
# @summary Main class for SlothSLOS deployment
#
# @param ensure Whether the resources should be present or absent
# @param user The system user to run slothslos-deploy.py and own the deployed
class slothslos (
    Wmflib::Ensure $ensure = present,
    String $user = 'sloth',
) {
    $home_dir = "/var/lib/${user}"

    ensure_packages(['sloth','python3-click'])

    systemd::sysuser { $user:
        ensure   => $ensure,
        home_dir => $home_dir,
        shell    => '/bin/bash',
    }

    file { $home_dir:
        ensure  => stdlib::ensure($ensure, 'directory'),
        owner   => $user,
        group   => $user,
        mode    => '0755',
        require => Systemd::Sysuser[$user],
    }

    file { '/usr/local/bin/slothslos_flatten':
        ensure => stdlib::ensure($ensure, 'file'),
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/slothslos/slothslos_flatten.py',
    }

    # The target to be started after puppet has updated git
    systemd::unit { 'slothslos-flatten.target':
        ensure  => $ensure,
        content => "[Unit]\nDescription=slothslos-flatten\n",
    }
}
