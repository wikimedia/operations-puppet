# gridengine/queue.pp
# Define a grid engine queue resource - this drops a config file in a directory
# for a grid engine queue. The actual queue is only created on running
# `qconf -Aq conf_file` or modified on running `qconf -Mq conf_file`
#
# The params are based on queue_conf - the sge queue configuration file format.
# See http://gridscheduler.sourceforge.net/htmlman/htmlman5/queue_conf.html
# for all parameters.
#
# [*hostlist]
# Space separated list of hosts or name of hostgroup, default NONE. For each host
# SGE maintains a queue instance for running jobs on that host.
#
# [*seq_no]
# Integer, default 0, spefifies queue's position in scheduling order. Set this as
# a monotonically increasing sequence
#
# [*np_load_avg_threshold]
# Load threshold for complex np_load_avg. Default: 1.75
#
# [*priority]
# Integer, default 0. Specifies nice value at which jobs in the queue will be run.
# Negative values (upto -20) = higher priority. Positive values (upto +20) =
# lower priority
#
# [*qtype]
# Type of queue, default BATCH INTERACTIVE. Can be batch, interactive, or combination.
#
# [*ckpt_list]
# List of checkpointing interface names. Default NONE
#
# [*rerun]
# Boolean, default false. Defines behavior for jobs that are aborted, set to true
# to restart automatically
#
# [*slots]
# Integer, default 50. Maximum number of concurrently executing jobs in the queue
#
# [*epilog]
# Executable path to a shell script that is started after a job's execution,
# with the same environment settings as the completed job. Default NONE
#
# [*terminate_method]
# Override default method(SIGKILL) used by to terminate a job.
#
# [*owner_list]
# List of users authorized to disable and suspend queue. Default NONE
#
# [*user_lists]
# Comma separated list of user access list names, controls which users have access
# to the queue. Default NONE


define gridengine::queue(
    $hostlist = 'NONE',
    $seq_no = 0,
    $np_load_avg_threshold = 1.75,
    $priority = 0,
    $qtype = 'BATCH INTERACTIVE',
    $ckpt_list = 'NONE',
    $pe_list = 'NONE',
    $rerun = false,
    $slots = 50,
    $epilog = 'NONE',
    $terminate_method = 'NONE',
    $owner_list = 'NONE',
    $user_lists = 'NONE',
    $s_rt = 'INFINITY',
    $h_rt = 'INFINITY',
    $s_cpu = 'INFINITY',
    $h_cpu = 'INFINITY',
    $h_vmem = 'INFINITY',
) {

    include gridengine::master

    $queue_config_dir = $gridengine::master::config_dirs['queues'][path]

    file { "${queue_config_dir}/${title}":
        ensure  => file,
        owner   => 'sgeadmin',
        group   => 'sgeadmin',
        mode    => '0664',
        content => template('gridengine/queue-conf.erb'),
        require => File[$queue_config_dir],
    }
}
