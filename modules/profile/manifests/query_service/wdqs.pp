# = Class: profile::query_service::wdqs
#
# This class defines a meta-class that pulls in all the query_service
# profiles necessary for a WDQS installation.
class profile::query_service::wdqs() {
    require ::profile::query_service::common
    require ::profile::query_service::blazegraph
    require ::profile::query_service::categories
    require ::profile::query_service::updater
    require ::profile::query_service::gui
}
