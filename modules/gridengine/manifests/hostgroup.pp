# gridengine/hostgroup.pp
# Define a grid engine hostgroup - this drops a config file in a directory
# for a hostgroup. The actual hostgroup is only created on running
# `qconf -Ahgrp conf_file`. This config file should only be used to
# create the hostgroup for the first time if it doesn't exist. The hostlists
# will be dynamically changed by sge admins using `qconf -mhgrp` and the actual
# hostgroup config can be viewed using `qconf -shgrp <hostgroup-name>`.
#
# See http://gridscheduler.sourceforge.net/htmlman/htmlman5/hostgroup.html
# for more info on hostgroups

define gridengine::hostgroup() {

    include gridengine::master

    $hostgroup_config_dir = $gridengine::master::config_dirs['hostgroups'][path]

    file { "${hostgroup_config_dir}/${title}":
        ensure  => file,
        owner   => 'sgeadmin',
        group   => 'sgeadmin',
        mode    => '0664',
        content => template('gridengine/hostgroup.erb'),
        require => File[$hostgroup_config_dir],
    }
}
