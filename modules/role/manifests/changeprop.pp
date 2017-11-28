# Role class for changeprop
#
# filtertags: labs-project-deployment-prep
class role::changeprop {
    system::role { 'changeprop':
        description => 'propagates events from the EventBus',
    }

    include ::profile::changeprop
}
