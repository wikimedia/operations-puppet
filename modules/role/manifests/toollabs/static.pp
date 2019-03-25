# filtertags: labs-project-tools
class role::toollabs::static {

    include ::toollabs::base
    include ::toollabs::static

    system::role { 'toollabs::static':
        description => 'Toolforge static http server',
    }
}
