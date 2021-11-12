# == Class profile::airflow
# Creates airflow::instance resources for each of $airflow_instances
#
# === Parameters
#
# [*airflow_instances*]
#   Hash of airflow::instance parameters keyed by name.  This will be
#   passed directly to the create_resources function. E.g.
#       myinstanceA:
#           service_user: ...
#           ...
#       myinstanceB:
#           service_user: ...
#           connections:
#             analytics-mariadb:
#               conn_type: mysql
#               host: ...
#               ...
#           ...
#
# [*airflow_instances_secrets*]
#   Any sensitive parameters that you don't want to put directly into puppet hiera
#   airflow_instances should be defined in puppet private hiera in this variable.
#   This is the exact same structure as $airflow_instances and will be merged on
#   top of it before being passed to create_resources.  The params here should be keyed by
#   the same instance names as in $airflow_instances.  E.g.
#       myinstanceA:
#           db_password: SECRET
#       myinstanceB:
#           db_password: SECRET
#           connections:
#             analytics-mariadb:
#               login: myuser
#               password: SECRET
#
#   Default: {}
#
# [*use_wmf_defaults]
#   If true, defaults for WMF Data Engineering airflow deployments
#   will be merged into each of the provided instance's params.
#   This reduces Hiera boilerplate needed with conventions we use to deploy Airflow.
#   Default: true
#
#   Notably:
#   - A scap::target for airflow-dags/$title is declared.
#     This target is expected to be for the data-engineering/airflow-dags
#     repository, and contains the instance specific dags_folder inside
#     at $title/dags.
#   - dags_folder will default to /srv/deployment/airflow-dags/$title/$title/dags
#   - Ferm will default to only allowing $ANALYTICS_NETWORKS to the airflow instance services.
#   - Common Airflow connections are configured.
#
# [*airflow_database_host_default*]
#   Hostname used in the default sql_alchemy_conn when use_wmf_defaults is true.
#   Default: an-coord1001.eqiad.wmnet
#
class profile::airflow(
    Hash    $airflow_instances             = lookup('profile::airflow::instances'),
    Hash    $airflow_instances_secrets     = lookup('profile::airflow::instances_secrets', { 'default_value' => {} }),
    Boolean $use_wmf_defaults              = lookup('profile::airflow::use_wmf_defaults', { 'default_value' => true }),
    String  $airflow_database_host_default = lookup('profile::airflow::database_host_default', { 'default_value' => 'an-coord1001.eqiad.wmnet' })
) {

    # If use_wmf_defaults, merge in smart per instance wmf defaults.
    $airflow_instances_with_defaults = $use_wmf_defaults ? {
        # Not $use_wmf_defaults, keep $airflow_instances as provided.
        default => $airflow_instances,

        # If $use_wmf_defaults, create a dynamic set of defaults for each instance's params
        # and merge those defaults in to create a new Hash of
        # { instance name => instance_params (with smart defaults) }
        true    => $airflow_instances.reduce({}) |$instances_accumulator, $key_value| {
            $instance_name = $key_value[0]
            $instance_params = $key_value[1]

            # Used in places where '-', etc. won't work, like database names.
            $instance_name_normalized = regsubst($instance_name, '\W', '_', 'G')


            # scap::targets should use the same $ensure for the airflow::instance.
            $scap_target_ensure = $instance_params['ensure'] ? {
                undef   => 'present',
                default => $instance_params['ensure']
            }

            # We don't want to deep_merge scap_targets, but allow a full override
            # if provided in $instance_params. I.e. If the configured instance
            # explicitly declares scap_targets, ONLY use those scap_targets,
            # don't use our smart scap_target defaults.
            $default_scap_targets = has_key($instance_params, 'scap_targets') ? {
                true    => undef,
                default => {
                    "airflow-dags/${instance_name}" => {
                        'deploy_user' => $instance_params['service_user'],
                        # The service user (that runs airflow) will be managed
                        # by airflow::instance, but the deploy_airflow ssh key
                        # is only used for scap deployments.  scap::target should
                        # not manage the user, but it should manage the ssh key.
                        'manage_user' => false,
                        'manage_ssh_key' => true,
                        # key_name must match a keyholder::agent declared in profile::keyholder::server::agents,
                        # which also must match an ssh keypair added in puppet private repo
                        # in modules/secret/secrets/keyholder.
                        'key_name' => 'deploy_airflow',
                        'ensure' => $scap_target_ensure
                    },
                }
            }

            # Default WMF (analytics cluster, for now) specific instance params.
            $default_wmf_instance_params = {
                'ferm_srange' => '$ANALYTICS_NETWORKS',
                'scap_targets' => $default_scap_targets,
                'airflow_config' => {
                    'core' => {
                        'dags_folder' => "/srv/deployment/airflow-dags/${instance_name}/${instance_name}/dags",
                        'security' => 'kerberos',
                        'executor' => 'LocalExecutor',
                        # NOTE: @db_user and @db_password should be provided via
                        # $airflow_instances_secrets as the $db_user and $db_password params.
                        # This ERb template string will be rendered in airflow::instance
                        # with those values.
                        'sql_alchemy_conn' => "mysql://<%= @db_user %>:<%= @db_password %>@${airflow_database_host_default}/airflow_${instance_name_normalized}?ssl_ca=/etc/ssl/certs/Puppet_Internal_CA.pem",
                    },
                },
                'connections' => {
                    'fs_local' => {
                        'conn_type' => 'fs',
                        'description' => 'Local filesystem on the Airflow Scheduler node',
                    },
                },
            }

            # Merge this instance's params with the smart wmf defaults we just constructed.
            $merged_instance_params = deep_merge($default_wmf_instance_params, $instance_params)

            # $instances_accumulator is just the reduce accumulator.
            # Merge it with the instance_name -> params we just created to
            # build up a new Hash of instances with smart defaults.
            deep_merge(
                $instances_accumulator,
                { $instance_name => $merged_instance_params },
            )
        },
    }

    # Finally, merge any airflow secrets into our airflow instances...
    $_airflow_instances = deep_merge($airflow_instances_with_defaults, $airflow_instances_secrets)

    # and declare the airflow::instances using our final Hash.
    create_resources('airflow::instance', $_airflow_instances)
}
