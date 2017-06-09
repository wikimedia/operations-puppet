# Role class for recommendation_api
class role::recommendation_api {

    system::role { 'role::recommendation_api': }

    include ::recommendation_api
}
