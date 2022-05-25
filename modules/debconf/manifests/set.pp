# SPDX-License-Identifier: Apache-2.0
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
#
# [*type*]
#   type of the value to set.
#   Default: string
#
define debconf::set($value, $type = 'string') {
    exec { "debconf-set-selections set ${type} ${title}":
        path    => '/usr/bin:/usr/sbin:/bin:/sbin',
        command => "echo set ${title} ${type} \"${value}\" | debconf-set-selections",
        unless  => "test \"$(echo get ${title} | debconf-communicate)\" = \"0 ${value}\"",
    }
}
