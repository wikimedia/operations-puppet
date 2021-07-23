# Role class for airflow
#
class role::search::airflow {
    system::role { 'airflow':
        description => 'orchestrates search platform data workflows',
    }

    include ::profile::standard
    include ::profile::base::firewall

    include ::profile::java
    include ::profile::analytics::cluster::client
    include ::profile::analytics::cluster::gitconfig
    include ::profile::analytics::cluster::repositories::statistics
    include ::profile::analytics::refinery
    include ::profile::analytics::airflow

    include ::profile::kerberos::client
    include ::profile::kerberos::keytabs
}
