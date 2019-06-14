# filtertags: labs-project-git labs-project-integration
class role::ci::slave::lite {
    requires_realm('labs')

    system::role { 'ci::slave::labs':
        description => 'Lightweight CI Jenkins slave on labs' }

    class { 'profile::ci::slave': }
}
