# Class: toollabs::master
#
# This role sets up the grid master in the Tool Labs model.
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
            toollabs::queue::task,
            toollabs::queue::continuous

    file { "${toollabs::collectors}/hostgroups":
        ensure    => directory,
        owner     => 'root',
        group     => 'root',
        mode      => '0755',
    }

    file { "${toollabs::collectors}/queues":
        ensure    => directory,
        owner     => 'root',
        group     => 'root',
        mode      => '0755',
    }

    gridengine::collectors::hostgroups { '@general':
        store => "${toollabs::collectors}/hostgroups",
    }

    gridengine::collectors::queues { 'webgrid-lighttpd':
        store  => "${toollabs::collectors}/queues",
        config => 'toollabs/gridengine/queue-webgrid.erb',
    }

    gridengine::collectors::queues { 'webgrid-tomcat':
        store  => "${toollabs::collectors}/queues",
        config => 'toollabs/gridengine/queue-webgrid.erb',
    }

    gridengine::collectors::queues { 'webgrid-generic':
        store  => "${toollabs::collectors}/queues",
        config => 'toollabs/gridengine/queue-webgrid.erb',
    }

    #
    # These things are done on toollabs::master because they
    # need to be done exactly once per project (they live on the
    # shared filesystem), and there can only be exactly one
    # gridmaster in this setup.  They could have been done on
    # any singleton instance.
    #

    # TODO: Remove after migration.
    file { "${toollabs::repo}/update-repo.sh":
        ensure => absent,
    }
    exec { 'Move Tools all packages to new structure':
        command => "/bin/mv -i ${toollabs::repo}/all/*.deb ${toollabs::repo}/ && /bin/rm -f ${toollabs::repo}/all/Packages && /bin/rmdir ${toollabs::repo}/all",
        onlyif => "/usr/bin/test -d ${toollabs::repo}/all",
        notify => Exec["Turn ${toollabs::repo} into deb repo"],
    }
    exec { 'Move Tools amd64 packages to new structure':
        command => "/bin/mv -i ${toollabs::repo}/amd64/*.deb ${toollabs::repo}/ && /bin/rm -f ${toollabs::repo}/amd64/Packages && /bin/rmdir ${toollabs::repo}/amd64",
        onlyif => "/usr/bin/test -d ${toollabs::repo}/amd64",
        notify => Exec["Turn ${toollabs::repo} into deb repo"],
    }
}

