# vim: set ts=2 sw=2 et :
class role::contint {

  system_role { 'role::contint':
    description => 'Continuous integration test server'
  }

  include wikimedia::contint
}
