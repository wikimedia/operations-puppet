require 'puppet'
require 'json'

Puppet::Type.type(:etcd_user).provide(:default) do

  commands :etcd_cmd => 'etcd-manage'

  @user_data = nil

  # Calls etcd-manage, returns the result
  def etcduser(*args)
    etcd_cmd(['user'] + args)
  end

  def exists?
    if @user_data
      return true
    else
      @user_data = JSON.load(etcduser('get', resource[:name]))
      return true
    end
  rescue Puppet::ExecutionFailure
    return false
  end

  def create
    etcduser('set', resource[:name], '-p', resource[:password],
             '--roles', resource[:roles])
  rescue Puppet::ExecutionFailure
    raise Puppet::ExecutionFailure, "Failed to add the user to etcd"
  end

  def destroy
    return unless exists?
    etcduser('delete', resource[:name])
    @user_data = nil
  end

  # Gets the roles
  def roles
    return unless exists?
    @user_data['roles']
  end

  def roles=(value)
    should = value.sort
    is = roles.sort
    if should != is
      etcduser('set', resource[:name], '--roles', should)
    end
  rescue Puppet::ExecutionFailure
    raise Puppet::ExecutionFailure, "Failed to sync the roles #{should} for user #{resource[:name]}"
  end

  def refresh_password
    etcduser('set', resource[:name], '-p', resource[:password])
  end
end
