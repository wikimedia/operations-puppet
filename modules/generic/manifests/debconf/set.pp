# Definition: generic::debconf::set
# Changes a debconf value
#
# Parameters:
# - $title
#       Debconf setting, e.g. mailman/used_languages
# - $value
#       The value $title should be set to
define generic::debconf::set($value) {
    exec { "debconf-communicate set ${title}":
        path    => '/usr/bin:/usr/sbin:/bin:/sbin',
        command => "echo set ${title} \"${value}\" | debconf-communicate",
        unless  => "test \"$(echo get ${title} | debconf-communicate)\" = \"0 ${value}\""
    }
}
