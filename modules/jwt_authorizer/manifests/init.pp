# SPDX-License-Identifier: Apache-2.0
# Installs dependencies for jwt-authorizer.
#
# @param ensure Package state.
class jwt_authorizer(
    Wmflib::Ensure $ensure = 'present',
) {
    package { 'jwt-authorizer':
        ensure => stdlib::ensure($ensure, 'package'),
    }

    file { '/etc/jwt-authorizer':
        ensure => stdlib::ensure($ensure, 'directory'),
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }
}
