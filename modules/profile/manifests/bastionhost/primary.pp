class role::bastion::primary {
    system::role { $name: }
    class{'::profile::bastionhost::general'}
}