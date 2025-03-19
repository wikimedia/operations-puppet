# SPDX-License-Identifier: Apache-2.0
# == Class: profile::scap::spiderpig
#
# Set up SpiderPig services
class profile::scap::spiderpig (
    Wmflib::Ensure             $ensure_services = 'present', # lint:ignore:wmf_styleguide
    Stdlib::Port::Unprivileged $spiderpig_port  = lookup('profile::scap::spiderpig::port', {'default_value' => 9000}),
    String                     $spiderpig_user  = lookup('profile::mediawiki::system_users::spiderpig_user', {'default_value' => 'spiderpig'})
) {
    systemd::service { 'spiderpig-jobrunner':
        ensure  => $ensure_services,
        content => template('profile/scap/spiderpig-jobrunner.service.erb'),
    }

    systemd::service { 'spiderpig-apiserver':
        ensure  => $ensure_services,
        content => template('profile/scap/spiderpig-apiserver.service.erb'),
    }
}
