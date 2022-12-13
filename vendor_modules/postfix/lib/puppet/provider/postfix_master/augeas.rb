Puppet::Type.type(:postfix_master).provide(:augeas, parent: Puppet::Type.type(:augeasprovider).provider(:default)) do
  desc 'Uses Augeas API to update a master.cf service.'

  default_file { '/etc/postfix/master.cf' }

  lens { 'Postfix_Master.lns' }

  confine feature: :augeas

  resource_path do |resource|
    service = resource[:service]
    type    = resource[:type]
    "$target/#{service}[type = '#{type}']"
  end

  def self.instances
    augopen do |aug|
      resources = []
      aug.match("$target/*[label()!='#comment']").each do |spath|
        service      = path_label(aug, spath)
        type         = aug.get("#{spath}/type")
        private      = aug.get("#{spath}/private")
        unprivileged = aug.get("#{spath}/unprivileged")
        chroot       = aug.get("#{spath}/chroot")
        wakeup       = aug.get("#{spath}/wakeup")
        limit        = aug.get("#{spath}/limit")
        command      = aug.get("#{spath}/command")
        entry = {
          name:         "#{service}/#{type}",
          ensure:       :present,
          service:      service,
          type:         type,
          private:      private,
          unprivileged: unprivileged,
          chroot:       chroot,
          wakeup:       wakeup,
          limit:        limit,
          command:      command,
        }
        resources << new(entry)
      end
      resources
    end
  end

  def create
    augopen! do |aug|
      service = resource[:service]
      type = resource[:type]
      aug.set("$target/#{service}[type = '#{type}']/type", type)
      ['private', 'unprivileged', 'chroot', 'wakeup', 'limit', 'command'].each do |attr|
        aug.set("$target/#{service}[type = '#{type}']/#{attr}", resource[attr.to_sym])
      end
    end
  end

  def destroy
    augopen! do |aug|
      aug.rm('$resource')
    end
  end

  attr_aug_accessor(:private)
  attr_aug_accessor(:unprivileged)
  attr_aug_accessor(:chroot)
  attr_aug_accessor(:wakeup)
  attr_aug_accessor(:limit)
  attr_aug_accessor(:command)
end
