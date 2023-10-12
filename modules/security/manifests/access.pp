# SPDX-License-Identifier: Apache-2.0
# == security::access ==
#
# This class is included implicitly by security::access::config resources
# to create the access.conf.d directory and add access.conf checking to
# the system PAM configuration.
#

class security::access () {
    concat { '/etc/security/access.conf':
        owner => 'root',
        group => 'root',
        mode  => '0444',
    }

    file { '/etc/security/access.conf.d':
        ensure  => absent,
        recurse => true,
        purge   => true,
        force   => true,
    }

    security::pam::config { 'local-pam-access':
        source => 'puppet:///modules/security/local-pam-access',
    }
}

