# Include this class to collect exported host key resources
# so that the collecting machine knows the host keys of all
# the other hosts that have exported their host keys through
# ppuppet.

class ssh::hostkeys_collect {
  if $::hostname =~ /^(fenari)|(tin)|(bast1001)$/ {
    $potm = 'True'
  } elsif $::instancename == 'deployment-bastion' {
    $potm = 'True'
  } else {
    # Do this about twice a day
    $potm = inline_template('<%= srand ; (rand(25) == 5).to_s.capitalize -%>')
  }

  if $potm == 'True' {
    notice("Collecting SSH host keys on ${::hostname}.")
    # Install all collected ssh host keys
    Ssh::Hostkey <<| |>>
  }
}
