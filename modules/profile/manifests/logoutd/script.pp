# SPDX-License-Identifier: Apache-2.0
# @summary resource used to install logout.d scripts into the logout.d folder.
#   All scripts must be CLI programs which implement a specific API.  See T283242
#   for more details
# @param source a puppet Source to the script file
# @param content String content of the script
define profile::logoutd::script (
    Integer[1,99]                $priority = 50,
    Optional[Stdlib::Filesource] $source   = undef,
    Optional[String]             $content  = undef,
) {
    include profile::logoutd
    unless $source or $content {
        fail('must provide either $source or $content')
    }
    if $source and $content {
        fail('must provide only one of $source or $content')
    }
    $file_name = sprintf('%s/%02d-%s', $profile::logoutd::base_dir, $priority, $title)
    file { $file_name:
        ensure  => file,
        owner   => $profile::logoutd::owner,
        group   => $profile::logoutd::group,
        mode    => '0550',
        source  => $source,
        content => $content,
    }
}
