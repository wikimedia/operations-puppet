class role::paws_internal {
    system::role { 'PAWS internal': }
    include ::standard
    include ::role::paws_internal::jupyterhub
    include ::role::analytics_cluster::client
    include ::role::paws_internal::mysql_access
}
