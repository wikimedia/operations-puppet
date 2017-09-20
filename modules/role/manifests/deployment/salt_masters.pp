# === Class role::deployment::salt_masters
# Installs deployment-related data to the salt master
#
# filtertags: labs-project-servermon
class role::deployment::salt_masters(
    $deployment_server = hiera('deployment_server', 'tin.eqiad.wmnet'),
) {
}
