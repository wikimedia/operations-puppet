# Mark the status flag of a debconf value as "seen", i.e. no longer prompt for it
# This suppresses debconf prompts for values which are either configured via
# debconf::set or configured via package defaults
#
# === Parameters
#
# [*title*]
#   debconf question, e.g. wireshark-common/install-setuid

define debconf::seen($value) {
    exec { "set debconf flag seen for ${title}":
        path    => '/usr/bin:/usr/sbin:/bin:/sbin',
        command => "echo fset ${title} seen true | debconf-communicate",
        unless  => "test \"$(echo fget ${title} seen | debconf-communicate)\" = \"0 true\"",
    }
}
