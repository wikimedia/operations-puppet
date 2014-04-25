# resource decom-user
#
# Try our very hardest to wipe out all traces of an existing user.
#
define decom-user($username=$title, $uid) {

    if $realm == labs {
        fail("You probably don't want to include this on labs.")
    }

    if defined(user[$username]) {
        # A user really needs to be removed from admins.pp before
        #  being added to the decom list.
        fail("User ${username} is both defined and decommissioned.")
    } else {
        # remove from /etc/passwd
        user { $username:
            name   =>     username,
            uid    =>     $uid,
            ensure =>     absent,
            managehome => true,
        }

        # remove any remaining owned files
        #  NOTE:  Expensive!   We limit this to a single
        #         run if and only if the homedir exists.
        #         Of course, that means we need to do this before
        #         we rm the homedir.
        exec { "disown ${username}":
            command => "/usr/bin/find / -user ${uid} -print0 | xargs -0 chown -h 0",
            onlyif  => "/usr/bin/test -d /home/${username}",
            timeout => 1200,
            require => user[$username],
            returns => ['123','0'],
        }

        # remove homedir
        #  NOTE:  $managehome, above, is documented as doing this,
        #         but it really doesn't.
        exec { "/bin/rm -rf /home/${username}":
            onlyif  => "/usr/bin/test -d /home/${username}",
            require => exec["disown ${username}"],
        }
    }
}
