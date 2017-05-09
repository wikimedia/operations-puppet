# gridengine/quota.pp
# Define a grid engine Resource Quota Set(RQS) - this drops a config file in a directory
# for a RQS. The actual RQS is only created on running
# `qconf -Arqs conf_file` or modified on running `qconf -Mrqs conf_file`
#
# [*description]
# Optional string, default NONE. Description for the RQS
#
# [*limit]
# Required param, String.
# See http://gridscheduler.sourceforge.net/htmlman/htmlman5/sge_resource_quota.html
# for all details on configuring Resource Quota Set limits.

define gridengine::quota(
    $limit,
    $description = 'NONE',
) {

    include gridengine::master

    $quota_config_dir = $gridengine::master::config_dirs['quotas'][path]

    file { "${quota_config_dir}/${title}":
        ensure  => file,
        owner   => 'sgeadmin',
        group   => 'sgeadmin',
        mode    => '0664',
        content => template('gridengine/resource-quota-set.erb'),
        require => File[$quota_config_dir],
    }
}
