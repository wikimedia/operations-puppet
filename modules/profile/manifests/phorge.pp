# SPDX-License-Identifier: Apache-2.0
# https://we.phorge.it - fork of Phabricator
class profile::phorge {

    wmflib::dir::mkdir_p('/srv/phorge')

    git::clone { 'phorge':
        ensure    => 'present',
        origin    => 'https://we.phorge.it/source/phorge.git',
        directory => '/srv/phorge',
        branch    => 'master',
    }
}
