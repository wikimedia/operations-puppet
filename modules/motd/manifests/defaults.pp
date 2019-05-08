# == Class: motd::defaults
#
# This provides defaults motd scripts, a generic but cleaned up (no help text)
# mixture of what Debian usually ship in their motd. This is needed as
# the motd module recursively manages the update-motd.d directory.
#
# This is meant to be generic. DO NOT INCLUDE SITE-SPECIFIC INFORMATION HERE.

class motd::defaults {
    # print uname & distribution release
    motd::script { 'header':
        ensure   => present,
        priority => 0,
        content  => "#!/bin/sh\nuname -snrvm\nlsb_release -s -d\n\n",
    }

    # print /etc/motd.tail, useful & harmless enough
    motd::script { 'footer':
        ensure   => present,
        priority => 99,
        content  => "#!/bin/sh\n[ -f /etc/motd.tail ] && cat /etc/motd.tail || true\n",
    }
}
