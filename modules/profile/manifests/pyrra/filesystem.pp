# SPDX-License-Identifier: Apache-2.0
# == Class: profile::pyrra::filesystem
#

class profile::pyrra::filesystem (
) {

    include profile::pyrra::filesystem::slos

    class { 'pyrra::filesystem': }

}
