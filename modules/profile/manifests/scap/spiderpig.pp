# SPDX-License-Identifier: Apache-2.0
# == Class: profile::scap::spiderpig
#
# Set up SpiderPig services

class profile::scap::spiderpig (
    Wmflib::Ensure             $ensure_services = 'present', # lint:ignore:wmf_styleguide
    Stdlib::Port::Unprivileged $spiderpig_port  = lookup('profile::scap::spiderpig::port', {'default_value' => 9000}),
) {
    $spiderpig_user = 'spiderpig'
    $uid = assert_type(Admin::UID::System::Global, 929)
    $gid = assert_type(Admin::UID::System::Global, 929)
    $home_dir = assert_type(Stdlib::Unixpath, '/var/lib/spiderpig')

    file { $home_dir:
        ensure => directory,
        owner  => $uid,
        group  => $gid,
        mode   => '0755',
    }

    # TODO: Once we are in bookworm+, switch the following 2 resources to systemd-sysuser
    user { $spiderpig_user:
        uid     => $uid,
        gid     => $gid,
        comment => 'SpiderPig jobrunner/apiserver',
        home    => $home_dir,
        require => File[$home_dir],
    }

    group { $spiderpig_user:
        gid    => $gid,
        system => true,
    }


    systemd::service { 'spiderpig-jobrunner':
        ensure  => $ensure_services,
        content => template('profile/scap/spiderpig-jobrunner.service.erb'),
    }

    systemd::service { 'spiderpig-apiserver':
        ensure  => $ensure_services,
        content => template('profile/scap/spiderpig-apiserver.service.erb'),
    }
}
