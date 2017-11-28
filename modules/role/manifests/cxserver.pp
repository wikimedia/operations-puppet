# vim: set ts=4 et sw=4:
#
# filtertags: labs-project-deployment-prep

class role::cxserver {
    system::role { 'cxserver':
        description => 'content translation server'
    }
    include ::profile::cxserver
}
