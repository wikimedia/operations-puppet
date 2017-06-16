module Puppet::Parser::Functions
    newfunction(:unique_users, :arity => 2, :type => :rvalue) do |args|
        myhash, applied_groups = args

        users = []
        applied_groups.each do |group|
            if myhash['groups'].key?(group)
                users.push(myhash['groups'][group]['members'])
            end
        end

        users.flatten(2).uniq
    end
end
