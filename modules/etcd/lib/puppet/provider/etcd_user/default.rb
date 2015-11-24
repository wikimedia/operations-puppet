require 'puppet'

Puppet::Type.type(:etcd_user).provide(:default) do

  commands :etcd_cmd => 'etcd-manage'

  # Calls etcdctl, returns the result
  def etcduser(*args)
    debug args.join(" ")
    etcd_cmd(['user'] + args)
  end

  def exists?
    if etcduser('get', resource[:name])
      return true
    end
  rescue Puppet::ExecutionFailure
    return false
  end

  def create
    etcduser('add', resource[:name], '-p', resource[:password])
    etcduser('grant', resource[:name], '-roles', resource[:roles].join(","))
  rescue Puppet::ExecutionFailure
    raise Puppet::ExecutionFailure, "Failed to add the user to etcd"
  end

  def destroy
    etcduser('remove', resource[:name])
  end

  # Gets the roles
  def roles
    output = etcduser('get', resource[:name])
    output.split("\n").each do |line|
      debug line
      m = /^(\w+):\s*(.+?){0,1}$/.match(line)
      if m[1] == 'Roles'
        if m[2].nil?
          return []
        else
          return m[2].split(' ')
        end
      end
    end
  end

  def roles=(value)
    should = value.sort
    is = roles.sort
    if should != is
      to_grant = should - is
      to_revoke = is - should
      etcduser('grant', resource[:name], '-roles', to_grant.join(',')) unless to_grant.empty?
      etcduser('revoke', resource[:name], '--roles', to_revoke.join(',')) unless to_revoke.empty?
    end
  rescue Puppet::ExecutionFailure
    raise Puppet::ExecutionFailure, "Failed to sync the roles #{should} for user #{resource[:name]}"
  end

end
