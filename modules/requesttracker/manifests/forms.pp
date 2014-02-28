# sets up custom forms for a Wikimedia RT install
class requesttracker::forms {

  # the password-reset self-service form
  file { [
    '/usr/local/share/request-tracker4/html',
    '/usr/local/share/request-tracker4/html/Callbacks',
    '/usr/local/share/request-tracker4/html/Callbacks/Default',
    '/usr/local/share/request-tracker4/html/Callbacks/Default/Elements',
    '/usr/local/share/request-tracker4/html/Callbacks/Default/Elements/Login']:
      ensure => 'directory',
      owner  => 'root',
      group  => 'staff',
      mode   => '0755',
  }

  file {
    '/usr/local/share/request-tracker4/html/Callbacks/Default/Elements/Login/AfterForm':
      ensure => 'present',
      owner  => 'root',
      group  => 'staff',
      mode   => '0644',
      source => 'puppet:///modules/requesttracker/AfterForm',
  }

}

