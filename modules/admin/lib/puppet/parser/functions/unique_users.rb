module Puppet::Parser::Functions
    newfunction(:unique_users, :type => :rvalue) do |args|
        myhash = args[0]
        applied_groups = args[1]
        users = Array.new
        for group in applied_groups
            if myhash['groups'].key?(group)
                users.push(myhash['groups'][group]['members'])
            end
        end
        return users.flatten(1).uniq
    end
end
