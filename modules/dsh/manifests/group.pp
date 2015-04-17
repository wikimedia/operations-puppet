# == Class dsh::group
#
# Write a dsh group file
class dsh::group (
    $entires => [],
){
    file { "/etc/dsh/group/$title":
        content => join($entries, '\n'),
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
    }
}
