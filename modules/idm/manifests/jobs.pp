# SPDX-License-Identifier: Apache-2.0

class idm::jobs (
    String         $base_dir,
    String         $etc_dir,
    Wmflib::Ensure $present,
    String         $project,
    String         $venv
){

    systemd::service { 'rq-bitu':
        ensure  => $present,
        content => file('idm/rq-bitu.service')
    }

    profile::auto_restarts::service {'rq-bitu':
        ensure => $present,
    }

    systemd::service { 'rq-idm':
        ensure  => absent,
        content => file('idm/rq-bitu.service')
    }

    profile::auto_restarts::service {'rq-idm':
        ensure => absent,
    }
}
