#= Class: icinga::groups::misc
# Setup monitoring groups for misc clusters
#
class icinga::groups::misc {

    @monitoring::group { 'misc_eqiad':
        description => 'eqiad misc servers'
    }

    @monitoring::group { 'misc_codfw':
        description => 'codfw misc servers'
    }

    @monitoring::group { 'misc_esams':
        description => 'esams misc servers'
    }

    @monitoring::group { 'misc_ulsfo':
        description => 'ulsfo misc servers'
    }

}
