# == Class: robotstxt
#
# This is a utility module to easily write a robots.txt file
#
# == Parameters
#
# [*title*]
#   The class title is used as the path to place the file
#
# [*ensure*]
#   Ensure the rule file exists (or not)
#
# [*rules*]
#   An array of hash tables that can define comments/useragents/paths to filter.
#   The agents and paths can be arrays. The format is as follows:
#     [
#       {
#         'comment'    => 'Block the bad bots from everything!',
#         'useragents' => ['FooBot', 'BarBot'],
#         'paths'      => '/',
#       },
#       {
#         'comment'    => 'Block the bad path from everyone!',
#         'useragents' => '*',
#         'paths'      => ['/badpath', '/reallybadpaths'],
#       }
#     ]
#
define robotstxt (
    $ensure = present,
    $rules  = [],
) {
    file { "${title}/robots.txt":
        ensure  => $ensure,
        content => template('robotstxt/robots.txt.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
    }
}
