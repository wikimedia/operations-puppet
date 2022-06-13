# SPDX-License-Identifier: Apache-2.0
# Class: bigtop::hadoop::yarn::capacity_scheduler
#
# This class renders the /etc/hadoop/conf/capacity-scheduler.xml file from a map
# of properties provided in input.
#
# Note: Please remember that to enable the capacity scheduler and other global settings,
#       you'll need also to modify yarn-site.xml's properties.
#
# == Parameters
#
#  [*scheduler_settings*]
#    Settings (key/value pairs) that will be rendered in the capacity-scheduler.xml
#    file.
#
class bigtop::hadoop::yarn::capacity_scheduler (
    $scheduler_settings
) {

    file { '/etc/hadoop/conf/capacity-scheduler.xml':
        ensure  => 'present',
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        content => template('bigtop/hadoop/capacity-scheduler.xml.erb'),
        before  => Service['hadoop-yarn-resourcemanager'],
        # This is the base package that pulls in all the base hadoop ones in our
        # codebase, ensuring the creation of /etc/hadoop.
        require => Package['hadoop-client'],
    }
}
