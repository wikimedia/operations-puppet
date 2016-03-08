
# Role class for changeprop
class role::changeprop {

    system::role { 'role::changeprop':
        description => 'propagates events from the EventBus',
    }

    include ::changeprop
}

