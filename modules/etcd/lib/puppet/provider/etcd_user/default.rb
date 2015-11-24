Puppet::Type.type(:etcd_user).provide(:default) do

  commands :etcd_cmd => 'etcd-manage'

  # Calls etcdctl, returns the result
  def etcduser(*args)
    etcd_cmd('user' + args)
  end

  def exists?
    if etcduser(['get', resource[:name]])
      return true
    end
  rescue Puppet::ExecutionFailure
    return false
  end

  def create
    etcduser(['add', resource[:name], '-p', resource[:password]])
  rescue Puppet::ExecutionFailure
    raise Puppet::ExecutionFailure "Failed to add the user to etcd"
  end

  def destroy
    etcduser(['remove', resource[:name]])
  end

  # Gets the roles
  def roles
    output = etcduser(['get', resource[:name]])
    res = JSON.load(output)
    res['roles']
  end

  def roles=(value)
    should = value.sort
    is = roles.sort
    if should != is
      to_grant = should - is
      to_revoke = is - should
      etcduser(['grant', resource[:name], '-roles', to_grant.join(',')])
      etcduser(['revoke', resource[:name], '--roles', to_revoke.join(',')])
    end
  rescue Puppet::ExecutionFailure
    raise Puppet::ExectionFailure "Failed to sync the roles #{should} for user #{resource[:name]}"
  end

end
