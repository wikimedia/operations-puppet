# == Class role::wikimetrics
#
class role::wikimetrics {
    include ::wikimetrics::base
    include ::wikimetrics::db
    include ::wikimetrics::web
    include ::wikimetrics::queue
}
