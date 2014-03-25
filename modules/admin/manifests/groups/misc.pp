class admin::groups::misc {

    #assigned almost universally as primary user group
    @admin::group { 'wikidev':
               gid => 500,
    }
}
