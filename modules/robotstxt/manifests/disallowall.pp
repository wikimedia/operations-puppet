# == Class: robotstxt::disallowall
#
# This is a utility class to easily disallow all robots
#
# == Parameters
#
# [*title*]
#   The class title is used as the path to place the file
#
# [*ensure*]
#   Remove the rule (or keep it there)
#
define robotstxt::disallowall (
    $ensure  = present,
) {
    robotstxt { $title:
        ensure => $ensure,
        rules  => [
            {
                'comment'    => 'Disallow all bots',
                'useragents' => '*',
                'paths'      => '/',
            }
        ]
    }
}
