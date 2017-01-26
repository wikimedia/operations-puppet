# == Class: motd::defaults
#
# This provides defaults motd scripts, a generic but cleaned up (no help text)
# mixture of what Debian/Ubuntu usually ship in their motd. This is needed as
# the motd module recursively manages the update-motd.d directory.
#
# This is meant to be generic. DO NOT INCLUDE SITE-SPECIFIC INFORMATION HERE.

class motd::defaults {
    # print uname & distribution release
    # - Debian has only uname -snrvm, no distribution release
    # - Ubuntu lucid had a variant of this but with uname -a.
    # - Ubuntu precise/trusty have a Welcome text. They also prefer
    #   /etc/lsb-release over lsb_release which is deprecated in favor of
    #   /etc/os-release. The script claims that lsb_release is too slow but this
    #   hasn't observed here so far.
    motd::script { 'header':
        ensure   => present,
        priority => '00',
        content  => "#!/bin/sh\nuname -snrvm\nlsb_release -s -d\n\n",
    }

    # print /etc/motd.tail, useful & harmless enough
    # - shipped with Ubuntu lucid/precise but not trusty
    # - Debian used to support motd.tail pre-wheezy
    motd::script { 'footer':
        ensure   => present,
        priority => 99,
        content  => "#!/bin/sh\n[ -f /etc/motd.tail ] && cat /etc/motd.tail || true\n",
    }
}
