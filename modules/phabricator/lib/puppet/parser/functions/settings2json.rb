        require 'json'

module Puppet::Parser::Functions
    newfunction(:settings2json, :type => :rvalue) do |args|
        myhash = args[0]
        return myhash.to_json.to_str
        clean_hash = {}
        myhash.each do |key, value|
            #we need to convert our numeric strings e.g. '24' or "25"
            #to integers before json converstion to be compliant
            if !!(value =~ /^[-+]?[1-9]([0-9]*)?$/)
                myhash[key] = value.scan(/'(.+?)'|"(.+?)"|([^ ]+)/).flatten.compact[0].to_i
            end
        end
        return myhash.to_json.to_str
        #return Hash[clean_hash.sort].to_json
    end
end
