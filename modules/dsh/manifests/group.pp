# === define dsh::group
#
# collects and realizes all the resources defined with dsh::add_to_group
define dsh::group {
    file { "/etc/dsh/group/${title}":
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0444'
    }

    File_line <<| tag == "dsh::add::${title}" |>>
}
