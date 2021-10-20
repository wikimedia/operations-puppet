class role::ci::slave::package_builder {
  requires_realm('labs')

  system::role { 'ci::slave::package_builder':
    description => 'CI Debian package builder' }

  include ::profile::ci::package_builder
  include ::profile::ci::slave::labs::common

}
