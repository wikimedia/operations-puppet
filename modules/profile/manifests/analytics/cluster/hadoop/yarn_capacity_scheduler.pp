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
        # Maximum number of applications that can be pending and running.
        'yarn.scheduler.capacity.maximum-applications' => 10000,
        # Maximum percent of resources in the cluster which can be used to run
        # application masters i.e. controls number of concurrent running applications.
        'yarn.scheduler.capacity.maximum-am-resource-percent' => 0.1,
        # The ResourceCalculator implementation to be used to compare  Resources in the scheduler.
        # The default DefaultResourceCalculator only uses Memory while DominantResourceCalculator
        #  uses dominant-resource to compare multi-dimensional resources such as Memory, CPU etc.
        'yarn.scheduler.capacity.resource-calculator' => 'org.apache.hadoop.yarn.util.resource.DefaultResourceCalculator',
        # Number of missed scheduling opportunities after which the CapacityScheduler
        # attempts to schedule rack-local containers.
        # Typically this should be set to number of nodes in the cluster.
        'yarn.scheduler.capacity.node-locality-delay' => 78,
        # If a queue mapping is present, will it override the value specified by the user?
        'yarn.scheduler.capacity.queue-mappings-override.enable' => false,
        # Useful to enable/disable any new job in the cluster (for example to let it drain before maintenance)
        # 'yarn.scheduler.capacity.root.state' => 'STOPPED'
        # Or a specific leaf queue:
        # 'yarn.scheduler.capacity.root.users.default.state' => 'STOPPED'

        # Queue definitions
        # Sum of capacity (not max) needs to be 100 at any level/branch of the tree
        # First layer
        'yarn.scheduler.capacity.root.queues' => 'users, production',
        'yarn.scheduler.capacity.root.production.capacity' => 60,
        'yarn.scheduler.capacity.root.production.maximum-capacity' => -1,
        'yarn.scheduler.capacity.root.users.capacity' => 40,
        'yarn.scheduler.capacity.root.users.maximum-capacity' => -1,
        # Second layer (users)
        'yarn.scheduler.capacity.root.users.queues' => 'default, fifo',
        'yarn.scheduler.capacity.root.users.default.capacity' => 80,
        'yarn.scheduler.capacity.root.users.default.maximum-capacity' => -1,
        'yarn.scheduler.capacity.root.users.fifo.capacity' => 20,
        'yarn.scheduler.capacity.root.users.fifo.maximum-capacity' => -1,
        # Second layer (production)
        'yarn.scheduler.capacity.root.production.queues' => 'analytics,search,product,ingest',
        'yarn.scheduler.capacity.root.production.analytics.capacity' => 40,
        'yarn.scheduler.capacity.root.production.analytics.maximum-capacity' => -1,
        'yarn.scheduler.capacity.root.production.search.capacity' => 30,
        'yarn.scheduler.capacity.root.production.search.maximum-capacity' => -1,
        'yarn.scheduler.capacity.root.production.product.capacity' => 10,
        'yarn.scheduler.capacity.root.production.product.maximum-capacity' => -1,
        'yarn.scheduler.capacity.root.production.ingest.capacity' => 20,
        'yarn.scheduler.capacity.root.production.ingest.maximum-capacity' => -1,

        # Default mappings
        'yarn.scheduler.capacity.queue-mappings' => 'u:druid:production.analytics,u:analytics:production.analytics,u:analytics-search:production.search,u:analytics-product::production.product,g:analytics-privatedata-users:users.default',

        # Limits
        # https://docs.cloudera.com/HDPDocuments/HDP2/HDP-2.6.4/bk_yarn-resource-management/content/setting_user_limits.html
        'yarn.scheduler.capacity.root.production.user-limit-factor' => 2,
        'yarn.scheduler.capacity.root.users.default.user-limit-factor' => 2,
        'yarn.scheduler.capacity.root.production.analytics.minimum-user-limit-percent' => 50,
        'yarn.scheduler.capacity.root.production.search.minimum-user-limit-percent' => 100,
        'yarn.scheduler.capacity.root.production.product.minimum-user-limit-percent' => 100,
        'yarn.scheduler.capacity.root.users.default.minimum-user-limit-percent' => 10,
        'yarn.scheduler.capacity.root.users.default.maximum-application-lifetime' => 604800, # 1 week in seconds

        # Ordering policy
        'yarn.scheduler.capacity.root.production.analytics.ordering-policy' => 'fair',
        'yarn.scheduler.capacity.root.production.search.ordering-policy' => 'fair',
        'yarn.scheduler.capacity.root.production.product.ordering-policy' => 'fair',
        'yarn.scheduler.capacity.root.users.default.ordering-policy' => 'fair',
        'yarn.scheduler.capacity.root.users.fifo.ordering-policy' => 'fifo',

        # ACLs
        # Permissions cannot be reduced on the lower layer of the tree once set for a specific
        # queue, they can only be incremented.
        'yarn.scheduler.capacity.root.acl_submit_applications' => ' ',
        'yarn.scheduler.capacity.root.acl_administer_queue' => ' ',
        'yarn.scheduler.capacity.root.production.analytics.acl_submit_applications' => 'analytics,druid',
        'yarn.scheduler.capacity.root.production.analytics.acl_administer_queue' => 'analytics-admins',
        'yarn.scheduler.capacity.root.production.search.acl_submit_applications' => 'analytics-search',
        'yarn.scheduler.capacity.root.production.search.acl_administer_queue' => 'analytics-search-users,analytics-admins',
        'yarn.scheduler.capacity.root.production.product.acl_submit_applications' => 'analytics-product',
        'yarn.scheduler.capacity.root.production.product.acl_administer_queue' => 'analytics-product-users,analytics-admins',
        'yarn.scheduler.capacity.root.production.ingest.acl_submit_applications' => 'analytics',
        'yarn.scheduler.capacity.root.production.ingest.acl_administer_queue' => 'analytics-admins',
        'yarn.scheduler.capacity.root.users.default.acl_submit_applications' => 'analytics-privatedata-users',
        'yarn.scheduler.capacity.root.users.default.acl_administer_queue' => 'analytics-privatedata-users,analytics-admins',
        'yarn.scheduler.capacity.root.users.fifo.acl_submit_applications' => 'analytics-privatedata-users',
        'yarn.scheduler.capacity.root.users.fifo.acl_administer_queue' => 'analytics-privatedata-users,analytics-admins',

        # Preemption
        'yarn.scheduler.capacity.root.production.ingest.disable_preemption' => true,
    }

    $scheduler_settings = $base_settings + $extra_settings

    class { 'bigtop::hadoop::yarn::capacity_scheduler':
        scheduler_settings => $scheduler_settings,
    }
}
