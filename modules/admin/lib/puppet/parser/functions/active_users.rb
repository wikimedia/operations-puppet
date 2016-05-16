module Puppet::Parser::Functions
  newfunction(:active_users, :type => :rvalue) do |args|
    myhash = args[0]
    users = Array.new
    myhash['users'].each do |name, data|
      users.push name if data['ensure'] == 'present'
    end
    myhash['groups']['all-users']['members'] = users
  end
end
