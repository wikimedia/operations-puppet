require 'puppet'
require 'json'

Puppet::Type.type(:etcd_role).provide(:default) do

  commands :etcd_cmd => 'etcd-manage'

  @role_data = nil

  # Calls etcd-manage, returns the result
  def etcdrole(*args)
    etcd_cmd(['role'] + args)
  end

  def exists?
    if @role_data
      return true
    else
      @role_data = JSON.load(etcdrole('get', resource[:name]))
      return true
    end
  rescue Puppet::ExecutionFailure
    return false
  end

  def create
    acls = resource[:acls].map{ |k, v| "#{k}=#{v}" }
    etcdrole('set', resource[:name], '--acls', *acls)
  end

  def destroy
    return unless exists?
    etcdrole('delete', resource[:name])
    @role_data = nil
  end

  def acls
    return unless exists?
    @role_data['acls']
  end

  def acls=(value)
    create unless value == acls
  end
end
