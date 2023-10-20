# SPDX-License-Identifier: Apache-2.0
# @summary profile for sretest hosts
class profile::sretest {
    file { '/var/tmp/testing':
        ensure  => directory,
        recurse => true,
        purge   => true,
    }
}
