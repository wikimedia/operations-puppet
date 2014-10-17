# Class: toollabs::master
#
# This role sets up a grid master in the Tool Labs model.
#
# Parameters:
#
# Actions:
#
# Requires:
#
# Sample Usage:
#
class toollabs::master inherits toollabs {
    include gridengine::master,
        toollabs::infrastructure,
        toollabs::exec_environ,
        toollabs::gridnode,
        toollabs::hostgroup,
        toollabs::queue::task,
        toollabs::queue::continuous

    file { '/etc/gridengine/local/bin/gethgrp':
        ensure   => file,
        force        => true,
        owner        => 'root',
        group        => 'root',
        mode         => '0755',
        source       => 'puppet:///modules/gridengine/gethgrp',
    }

    toollabs::hostgroup::collector { 'general': }
    toollabs::hostgroup::collector { 'webgrid': }

    #
    # These things are done on toollabs::master because they
    # need to be done exactly once per project (they live on the
    # shared filesystem), and there can only be exactly one
    # gridmaster in this setup.  They could have been done on
    # any singleton instance.
    #

    file { $toollabs::repo:
        ensure  => directory,
        owner   => 'tools.admin',
        group   => 'tools.admin',
        mode    => '0755',
        require => File[$toollabs::sysdir],
    }

    file { "${toollabs::repo}/update-repo.sh":
        ensure  => file,
        owner   => 'tools.admin',
        group   => 'tools.admin',
        mode    => '0550',
        require => File[$toollabs::repo],
        source  => 'puppet:///modules/toollabs/update-repo.sh',
    }

}

