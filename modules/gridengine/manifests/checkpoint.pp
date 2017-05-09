# gridengine/checkpoint.pp
# Define a grid engine checkpoint - this drops a config file in a directory
# for a checkpoint. The actual RQS is only created on running
# `qconf -Ackpt conf_file` or modified on running `qconf -Mckpt conf_file`
#
# See http://gridscheduler.sourceforge.net/htmlman/htmlman5/checkpoint.html
# for more info on checkpoints
#
# [*ckpt_dir]
# Required param, String.
# Location at which checkpoints  of  potentially considerable size should be stored.

define gridengine::checkpoint(
    $ckpt_dir,
) {

    include gridengine::master

    $checkpoint_config_dir = $gridengine::master::config_dirs['checkpoints'][path]

    file { "${checkpoint_config_dir}/${title}":
        ensure  => file,
        owner   => 'sgeadmin',
        group   => 'sgeadmin',
        mode    => '0664',
        content => template('gridengine/checkpoint-conf.erb'),
        require => File[$checkpoint_config_dir],
    }
}
