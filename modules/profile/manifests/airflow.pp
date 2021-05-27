# == Class profile::airflow
# Creates airflow::instance resources for each of $airflow_instances
#
# === Parameters
# [*airflow_instances*]
#   Hash of airflow::instance parameters keyed by name.  This will be
#   passed directly to the create_resources function. E.g.
#       myinstanceA:
#           service_user: ...
#           ...
#       myinstanceB:
#           service_user: ...
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
#   Default: {}
#
class profile::airflow(
    Hash $airflow_instances         = lookup('profile::airflow::instances'),
    Hash $airflow_instances_secrets = lookup('profile::airflow::instances_secrets', {'default_value' => {}}),
) {
    $_airflow_instances = deep_merge($airflow_instances, $airflow_instances_secrets)
    create_resources('airflow::instance', $_airflow_instances)
}
