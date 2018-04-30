# Profile applied to the current dataset serving hosts
# Can be deprecated after migrating to labstore1006|7
class profile::dumps::web::xmldumps_active {
    require profile::dumps::web::xmldumps_common
}
