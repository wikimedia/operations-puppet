require 'facter/util/puppet_settings'  # provided by puppetlabs-stdlib

settings = [
  :localcacert,
  :ssldir,
  :hostpubkey,
  :hostprivkey,
  :hostcert,
]
Facter.add(:puppet_config) do
  confine :kernel => 'Linux'
  puppet_config = {}
  setcode do
    Facter::Util::PuppetSettings.with_puppet do
      settings.each do |setting|
        puppet_config[setting.to_s] = Puppet[setting]
      end
    end
    puppet_config
  end
end
