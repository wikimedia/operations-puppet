# projectgid.rb
#
# This fact provides ec2id (old-timey instance id) for instances in labs.
# This is used to set the puppet certname, among other things.

require 'facter'

Facter.add(:ec2id) do
  setcode do
    domain = Facter::Util::Resolution.exec("hostname -d").chomp
    if domain.include? "wmflabs"
      Facter::Util::Resolution.exec("curl http://169.254.169.254/1.0/meta-data/instance-id 2> /dev/null").chomp
    else
      ""
    end
  end
end
