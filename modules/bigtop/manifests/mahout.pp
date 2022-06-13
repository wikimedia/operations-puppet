# SPDX-License-Identifier: Apache-2.0
# == Class bigtop::mahout
# Installs mahout package.  You should only need to include this on
# nodes where users will run the mahout executable, i.e. client submission nodes.
#
class bigtop::mahout {
    package { 'mahout':
        ensure => 'installed',
    }
}
