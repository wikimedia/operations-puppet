# == Define: debconf::set
#
# Sets a debconf value, useful for preseeding package configuration before
# installing them.
#
# === Parameters
#
# [*title*]
#   debconf question, e.g. mailman/used_languages
#
# [*value*]
#   preseeded answer to the debconf question

define debconf::set($value) {
    exec { "debconf-communicate set ${title}":
        path    => '/usr/bin:/usr/sbin:/bin:/sbin',
        command => "echo set ${title} \"${value}\" | debconf-communicate",
        unless  => "test \"$(echo get ${title} | debconf-communicate)\" = \"0 ${value}\"",
    }
}
