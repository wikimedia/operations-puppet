# Licence AGPL version 3 or later
#
# Class containing a user for running WMDE releated analytics scripts.
#
# @author Addshore
class statistics::wmde::user($homedir = '/srv/analytics-wmde') {

    $username = 'analytics-wmde'

    group { $username:
        ensure => 'present',
        name   => $username,
    }

    user { $username:
        ensure     => 'present',
        shell      => '/bin/bash',
        managehome => false,
        home       => $homedir,
        system     => true,
        require    => Group[$username],
    }

}
