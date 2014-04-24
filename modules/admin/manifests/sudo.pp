# A defined type for user/group sudo privilege management
#
# === Parameters
#
# [*name*]
#  If this is for a user or group this is the user or group name.
#  If this is a one-off it is the name of the on-system sudo file
#
# [*ensure*]
#  Add or remove the priv definition in /etc/sudoers.d [ "present" | "absent"]
#
# [*user*]
#  The username of the user to be given priviledges.
#
#  WARNING:  Use for user oneoffs.  Sudo privs should be handled in
#            the main user/group definition in almost all cases.
#
# [*comment*]
#  In case of a non-user definition/non-group definition priv a comment
#  can be provided.
#
# [*privs*]
#  An array of lines to be included in a sudoers.d/ file
#
# [*is_group*]
#  Boolean value to determine if this is a group.
#  Group declarations in sudo terms need a '%' prepend
#

define admin::sudo(
    $ensure='present',
    $user=undef,
    $comment=undef,
    $privs=[],
    $is_group=false,
)
    {

    if ($user) and ($is_group) {
        fail("${user} specified as group")
    }

    if ($user) {
        $priv_holder = $user
    }
    else {
        $priv_holder = $name
    }

    if member($privs, 'absent') {
        $final_ensure = 'absent'
    }
    else {
        $final_ensure = $ensure
    }

    #WARNING: if path supplied is an existing dir Puppet will swallow this silently
    $filepath = "/etc/sudoers.d/${name}"
    file { $filepath:
        ensure  => $final_ensure,
        owner   => 'root',
        group   => 'root',
        mode    => '0440',
        content => template('admin/sudoers.erb'),
        tag     => 'sudoers',
    }

    #messing up sudo can have dire consquences.  here we are linting
    #the final sudo file.  if bad, remove and throw an exception.
    exec { "${name}_sudo_linting":
        command    => "rm -f /etc/sudoers.d/${name} && false",
        unless     => "test -e ${filepath} && /usr/sbin/visudo -cf ${filepath} || exit 0",
        path       => '/bin:/usr/bin',
        subscribe  => File[$filepath],
    }
}
