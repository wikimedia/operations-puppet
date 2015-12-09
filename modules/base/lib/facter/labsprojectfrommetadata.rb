# labsprojectfrommetadata.rb
#
# This fact pulls the labs project out of instance metadata

require 'facter'

Facter.add(:labsprojectfrommetadata) do
  setcode do
    domain = Facter::Util::Resolution.exec("hostname -d").chomp
    if domain.end_with? ".wmflabs"
      # query the nova metadata service at 169.254.169.254
      metadata = Facter::Util::Resolution.exec("curl -f http://169.254.169.254/openstack/2013-10-17/meta_data.json/ 2> /dev/null").chomp
      metadata[/project-id\":\ \"(.*?)\"/, 1]
    else
      nil
    end
  end
end
