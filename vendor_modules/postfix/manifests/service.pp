# @!visibility private
class postfix::service {

  service { $postfix::service_name:
    ensure     => running,
    enable     => true,
    hasstatus  => true,
    hasrestart => true,
  }
}
