# == Define dsh::monitor::groups
#
# Checks that this host belongs to dsh group(s)
#
define dsh::monitor::groups( $groups = [] ) {
    $groups_string = join( $groups, ' ' )

    monitor_service { 'dsh':
        description   => 'dsh groups',
        check_command => "check_dsh_groups!${groups_string}",
    }
}
