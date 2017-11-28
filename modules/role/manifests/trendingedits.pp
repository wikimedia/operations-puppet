# Role class for trendingedits
class role::trendingedits {
    system::role { 'trendingedits':
        description => 'computes the list of currently-trending articles',
    }

    include ::profile::trendingedits
}
