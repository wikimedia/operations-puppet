# Class: profile::analytics::cluster::hadoop::yarn_capacity_scheduler
#
# Capacity scheduler config tailored for the Hadoop Analytics Cluster.
# This class renders the capacity-scheduler.xml file, but it requires some options
# to be set in yarn-site.xml (via hadoop's common config) to be enabled:
#
# yarn.resourcemanager.scheduler.monitor.enable: true
# yarn.acl.enable: true
#
# This profile needs to be included on the Hadoop master nodes only.
#
# == Parameters
#
#  [*base_settings*]
#    Settings that are common/shared to all clusters that use this scheduler.
#
#  [*extra_settings*]
#    Settings that can be selectively enabled/disabled on top of the base ones.
#    It is useful when testing new properties on a single cluster (like testing)
#    before considering to add the option to the base_settings.
#
class profile::analytics::cluster::hadoop::yarn_capacity_scheduler (
    $extra_settings = lookup('profile::analytics::cluster::hadoop::yarn_capacity_scheduler::extra_settings', { 'default_value' => {} }),
) {

    $base_settings = {
        # Global config
        # Maximum number of applications that can be pending and running (same as hadoop default).
        'yarn.scheduler.capacity.maximum-applications' => 10000,
        # Maximum percent of resources in the cluster which can be used to run
        # application masters i.e. controls number of concurrent running applications
        # (same as hadoop default).
        'yarn.scheduler.capacity.maximum-am-resource-percent' => 0.1,
        # The ResourceCalculator implementation to be used to compare  Resources in the scheduler.
        # The default DefaultResourceCalculator only uses Memory while DominantResourceCalculator
        #  uses dominant-resource to compare multi-dimensional resources such as Memory, CPU etc.
        'yarn.scheduler.capacity.resource-calculator' => 'org.apache.hadoop.yarn.util.resource.DominantResourceCalculator',
        # Number of missed scheduling opportunities after which the CapacityScheduler
        # attempts to schedule rack-local containers.
        # Typically this should be set to number of nodes in the cluster.
        'yarn.scheduler.capacity.node-locality-delay' => 78,
        # If a queue mapping is present, will it override the value specified by the user?
        'yarn.scheduler.capacity.queue-mappings-override.enable' => false,
        # Useful to enable/disable any new job in the cluster (for example to let it drain before maintenance)
        # Individual queues are not re-enabled by setting the yarn.scheduler.capacity.root.state to RUNNING,
        # so all 4 queues have a setting here. Specific leaf queues can also be managed this way.
        'yarn.scheduler.capacity.root.fifo.state' => 'RUNNING',
        'yarn.scheduler.capacity.root.default.state' => 'RUNNING',
        'yarn.scheduler.capacity.root.production.state' => 'RUNNING',
        'yarn.scheduler.capacity.root.essential.state' => 'RUNNING',

        # Queue definitions
        # Sum of capacity (not max) needs to be 100 at any level/branch of the tree.
        # The -1 value for maximum-capacity means no maximum. We set this to maximize
        # usage elasticity.
        # First layer
        'yarn.scheduler.capacity.root.queues' => 'fifo,default,production,essential',
        'yarn.scheduler.capacity.root.fifo.capacity' => 5,
        'yarn.scheduler.capacity.root.fifo.maximum-capacity' => -1,
        'yarn.scheduler.capacity.root.default.capacity' => 35,
        'yarn.scheduler.capacity.root.default.maximum-capacity' => -1,
        'yarn.scheduler.capacity.root.production.capacity' => 50,
        'yarn.scheduler.capacity.root.production.maximum-capacity' => -1,
        'yarn.scheduler.capacity.root.essential.capacity' => 10,
        'yarn.scheduler.capacity.root.essential.maximum-capacity' => -1,

        # Default mappings
        # PLEASE NOTE: use only the leaf queue names, not full path.
        # Example: root.production BAD, production GOOD
        'yarn.scheduler.capacity.queue-mappings' => 'u:druid:production,u:analytics:production,u:analytics-platform-eng:production,u:analytics-research:production,u:analytics-search:production,u:analytics-product:production,g:analytics-privatedata-users:default',

        # Limits
        # https://docs.cloudera.com/HDPDocuments/HDP2/HDP-2.6.4/bk_yarn-resource-management/content/setting_user_limits.html
        # https://hadoop.apache.org/docs/r2.10.1/hadoop-yarn/hadoop-yarn-site/CapacityScheduler.html
        # The user limit factor is a multiplier used to allow users of a specific queue to take up to X
        # times the resource allocated (as min value) for the queue. It is needed to allow/control elasticity,
        # so users can overcome Yarn default limits in case there are free resources.
        # Since fifo queue size is small, use a large limit-factor
        'yarn.scheduler.capacity.root.fifo.user-limit-factor' => 5,
        'yarn.scheduler.capacity.root.default.user-limit-factor' => 2,
        'yarn.scheduler.capacity.root.production.user-limit-factor' => 2,
        'yarn.scheduler.capacity.root.essential.user-limit-factor' => 10,
        # The user limit percent is different from the factor, since it is about how many users can run jobs on a queue
        # at any given time. For example, if we set:
        # 'yarn.scheduler.capacity.root.production.analytics.minimum-user-limit-percent' => 50,
        # we want to allow up to two users concurrently in the queue (druid and analytics), leaving the others waiting.
        # If we use '25', we'll allow a max of 4 different users, etc..
        'yarn.scheduler.capacity.root.fifo.minimum-user-limit-percent' => 100,
        'yarn.scheduler.capacity.root.default.minimum-user-limit-percent' => 10,
        'yarn.scheduler.capacity.root.production.minimum-user-limit-percent' => 20,
        'yarn.scheduler.capacity.root.essential.minimum-user-limit-percent' => 50,

        # Max lifetime for a Yarn application
        'yarn.scheduler.capacity.root.default.maximum-application-lifetime' => 604800, # 1 week in seconds
        'yarn.scheduler.capacity.root.fifo.maximum-application-lifetime' => 604800, # 1 week in seconds

        # Ordering policy
        'yarn.scheduler.capacity.root.fifo.ordering-policy' => 'fifo',
        'yarn.scheduler.capacity.root.default.ordering-policy' => 'fair',
        'yarn.scheduler.capacity.root.production.ordering-policy' => 'fair',
        'yarn.scheduler.capacity.root.essential.ordering-policy' => 'fair',

        # Labels
        # https://hadoop.apache.org/docs/r2.10.0/hadoop-yarn/hadoop-yarn-site/NodeLabel.html
        # Only one label can be assigned to every node, by default ending up in the DEFAULT_PARTITION.
        # When a label is assigned, it creates a partition between the nodes, and the Capacity scheduler
        # settings gets "duplicated" (so all the queues, etc..). In this case we want just one queue to
        # use the GPU label, so we concentrate all the capacity to it.
        'yarn.scheduler.capacity.root.accessible-node-labels' => 'GPU',
        'yarn.scheduler.capacity.root.accessible-node-labels.GPU.capacity' => '100',
        'yarn.scheduler.capacity.root.fifo.accessible-node-labels' => 'GPU',
        'yarn.scheduler.capacity.root.fifo.accessible-node-labels.GPU.capacity' => '100',

        # ACLs
        # Permissions cannot be reduced on the lower layer of the tree once set for a specific
        # queue, they can only be incremented.
        # Note: permissions values are in the form 'users groups'. If no user is specified but a
        #       group is, the value should start with a space
        'yarn.scheduler.capacity.root.acl_submit_applications' => ' ',
        'yarn.scheduler.capacity.root.acl_administer_queue' => ' ',
        'yarn.scheduler.capacity.root.fifo.acl_submit_applications' => ' analytics-privatedata-users',
        'yarn.scheduler.capacity.root.fifo.acl_administer_queue' => ' analytics-privatedata-users',
        'yarn.scheduler.capacity.root.default.acl_submit_applications' => ' analytics-privatedata-users',
        'yarn.scheduler.capacity.root.default.acl_administer_queue' => ' analytics-privatedata-users',
        'yarn.scheduler.capacity.root.production.acl_submit_applications' => 'analytics,analytics-platform-eng,analytics-research,druid,analytics-search,analytics-product',
        # '%user' below refers to the submitter of the application/job. Thus, the submitter can manage/kill their own jobs in production.
        # Additionaly, any member from the group list can manage/kill any job in production
        'yarn.scheduler.capacity.root.production.acl_administer_queue' => '%user analytics-admins,analytics-platform-eng-admins,analytics-research-admins,analytics-search-users,analytics-product-users',
        'yarn.scheduler.capacity.root.essential.acl_submit_applications' => 'analytics,druid',
        'yarn.scheduler.capacity.root.essential.acl_administer_queue' => ' analytics-admins',

        # Preemption
        'yarn.scheduler.capacity.root.essential.disable_preemption' => true,
    }

    $scheduler_settings = $base_settings + $extra_settings

    class { 'bigtop::hadoop::yarn::capacity_scheduler':
        scheduler_settings => $scheduler_settings,
    }
}
