# SPDX-License-Identifier: Apache-2.0
# == Define bigtop::alternative
# Runs update-alternatives command to create and set CDH related alternatives.
# This is usually used to name config directories after $cluster_name.
#
# == Parameters
# $link      - Symlink pointing to /etc/alternatives/$name.
# $path      - Location of one of the alternative target files.
# $priority  - integer; options with higher numbers have higher
#              priority in automatic mode.  Default: 50
#
# == Usage
#   bigtop::alternative { 'hadoop-conf':
#       link    => '/etc/hadoop/conf',
#       path    => $config_directory,
#   }
#
define bigtop::alternative(
    $link,
    $path,
    $priority = 50
)
{
    # Update $title alternatives to point $link at $path
    exec { "update-alternatives_${title}":
        command => "update-alternatives --install ${link} ${name} ${path} ${priority} && update-alternatives --set ${name} ${path}",
        unless  => "update-alternatives --query ${name} | grep -q 'Value: ${path}'",
        path    => '/bin:/usr/bin:/usr/sbin',
        require => File[$path],
    }
}
