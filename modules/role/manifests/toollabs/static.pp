# filtertags: labs-project-tools
class role::toollabs::static {

    include ::toollabs::base
    include ::toollabs::static

    system::role { 'toollabs::static':
        description => 'Tool Labs static http server',
    }
}
