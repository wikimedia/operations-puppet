# A defined type for user/group sudo priviledge management
#
# Manages:
#       Group sudo rights
#       User sudo rights
#
# === Parameters
#
# [*ensure*]
#   Add or remove the priv definition in /etc/sudoers.d [ "present" | "absent"]
#
# [*username*]
#   The username of the user to be given priviledges.
#
#   WARNING:  Use for user oneoffs.  Sudo privs should be handled in
#   the main user/group definition in almost all cases.
#
# [*filename*]
#   File to create in /etc/sudoers.d/.  This is usually autodetermined.
#
# [*comment*]
#   In case of a non-user definition/non-group definition priv a comment
#   can be provided.
#
# [*privs*]
#   An array of lines to be included in a sudoers.d/ file
#
# [*is_group*]
#   Boolean value to determine if this is a group.
#   Group declarations in sudo terms need a '%' prepend
#
define admin::sudo(
                        $ensure='present',
                        $user=undef,
                        $filename=undef,
                        $comment=undef,
                        $privs=[],
                        $is_group=false,
                   )
    {

    if ($user) and ($is_group) {
        fail("${user} specified as group")
    }

    if ($filename) {
        $suders_d = $filename
    }
    else {
        $sudoers_d = $name
    }

    if ($user) {
        $priv_holder = $user
    }
    else {
        $priv_holder = $name
    }

    file { "/etc/sudoers.d/${filename}":
        ensure  => $ensure,
        owner   => 'root',
        group   => 'root',
        mode    => '0440',
        content => template('admin/sudoers.erb'),
        tag     => 'sudoers',
    }
}
