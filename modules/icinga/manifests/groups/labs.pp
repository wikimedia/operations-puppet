#= Class: icinga::groups::labs
# Setup monitoring groups for labs servers
#
class icinga::groups::labs {

    @monitoring::group { 'labsnfs_eqiad':
        description => 'eqiad labsnfs server servers'
    }

    @monitoring::group { 'labsnfs_codfw':
        description => 'codfw labsnfs server servers'
    }
}
