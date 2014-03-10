# ec2id.rb
#
# This fact provides the instance type (aka 'flavor') of the running instance.
# Flavors are names like 'm1.small' or 'm1.large'.  In eqiad there are also
# flavors duplicated from pmtpa like 'pmtpa-3'.  This is necessary because
# default flavor names seem to vary by OpenStack version.

require 'facter'

Facter.add(:instancetype) do
  setcode do
    domain = Facter::Util::Resolution.exec("hostname -d").chomp
    if domain.include? "wmflabs"
      Facter::Util::Resolution.exec("curl http://169.254.169.254/2009-04-04/meta-data/instance-type 2> /dev/null").chomp
    else
      ""
    end
  end
end
