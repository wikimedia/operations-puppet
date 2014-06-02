# Definition: interface::setting
#
# Change an interface setting via augeas in /etc/network/interfaces

define interface::setting($interface, $setting, $value) {
    if $::lsbdistid == 'Ubuntu' and versioncmp($::lsbdistrelease, '10.04') >= 0 {
        augeas { "${interface}_${title}":
            context => "/files/etc/network/interfaces/*[. = '${interface}' and family = 'inet']",
            changes => "set ${setting} '${value}'",
        }
    }
}
