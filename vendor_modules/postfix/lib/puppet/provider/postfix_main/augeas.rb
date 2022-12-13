Puppet::Type.type(:postfix_main).provide(:augeas, parent: Puppet::Type.type(:augeasprovider).provider(:default)) do
  desc 'Uses Augeas API to update a main.cf setting.'

  default_file { '/etc/postfix/main.cf' }

  lens { 'Postfix_Main.lns' }

  confine feature: :augeas

  resource_path do |resource|
    setting = resource[:setting]
    "$target/#{setting}"
  end

  def self.instances
    augopen do |aug|
      resources = []
      aug.match("$target/*[label()!='#comment']").each do |spath|
        setting = path_label(aug, spath)
        value   = aug.get(spath)
        entry = {
          name:    setting,
          ensure:  :present,
          setting: setting,
          value:   value,
        }
        resources << new(entry)
      end
      resources
    end
  end

  def create
    augopen! do |aug|
      setting = resource[:setting]
      value   = resource[:value]
      aug.set("$target/#{setting}", value)
    end
  end

  def destroy
    augopen! do |aug|
      aug.rm('$resource')
    end
  end

  attr_aug_accessor(:value, label: :resource)
end
