# This is for the monitoring host to monitor the shared public addrs
class role::authdns::monitoring {
    include ::role::authdns::data
    create_resources(authdns::monitoring::global, $role::authdns::data::ns_addrs)
}
