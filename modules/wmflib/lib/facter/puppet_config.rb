desired_settings = {
  :master => [
    :localcacert,
    :ssldir,
  ],
  :main => [
    :localcacert,
    :ssldir,
    :hostpubkey,
    :hostprivkey,
    :hostcert,
  ]
}
Facter.add(:puppet_config) do
  confine :kernel => 'Linux'
  puppet_config = {}
  setcode do
    desired_settings.each_pair do |section, settings|
      settings.each do |setting|
        if section == :main
          puppet_config[setting] = Puppet[setting]
        else
          puppet_config[sections] = {} unless puppet_config.key?(sections)
          puppet_config[sections][settings] = Puppet.settings.values(
            Puppet[:environment].to_sym, section
          ).print(setting)
        end
      end
    end
    puppet_config
  end
end
