class role::ci::slave::package_builder {
  requires_realm('labs')

  include profile::ci::package_builder
  include profile::ci::slave::labs::common
}
