# === Define dsh::add_to_group
#
# Add a server to a dsh group as an exported file_line.
# The dsh group can then be realized by using dsh::group
#
define dsh::add_to_group {
    $group = $title
    @@file_line { "${::hostname}_in_dsh_${group}" :
        tag  => "dsh::add::${group}",
        path => "/etc/dsh/group/${group}",
        line => $::hostname,
    }
}
