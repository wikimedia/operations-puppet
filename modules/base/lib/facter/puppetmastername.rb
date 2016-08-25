# puppetmastername.rb
#
# Answers the question "what puppetmaster is set in puppet.conf?"

require 'facter'

Facter.add(:puppetmastername) do
  setcode do
    serverline = Facter::Util::Resolution.exec('grep -e "^server " /etc/puppet/puppet.conf | tail -n 1').chomp
    serverline.sub!(/server\s*=\s*/, "")
  end
end
