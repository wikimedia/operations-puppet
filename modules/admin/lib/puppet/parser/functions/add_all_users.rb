module Puppet::Parser::Functions
  newfunction(:add_all_users, :type => :rvalue) do |args|
    myhash = args[0]
    users = Array.new
    myhash['users'].each do |name, data|
      users.push name if data['ensure'] == 'present'
    end
    myhash['groups']['all-users']['members'] = users
    return myhash
  end
end
