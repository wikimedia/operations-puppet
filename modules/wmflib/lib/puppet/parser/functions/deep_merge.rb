class Hash
  def deep_merge(hash)
    hash.keys.each do |key|
      if hash[key].is_a? Hash and self[key].is_a? Hash
        self[key].deep_merge(hash[key])
        next
      end
      self[key] = hash[key]
    end
  end
end

module Puppet::Parser::Functions
  newfunction(:deep_merge, :type => :rvalue, :doc => <<-'ENDHEREDOC') do |args|
    Merges two or more hashes together and returns the resulting hash.

    For example:

        $hash1 = {'one' => 1, 'two', => 2}
        $hash2 = {'two' => 'dos', 'three', => 'tres'}
        $merged_hash = deep_merge($hash1, $hash2)
        # The resulting hash is equivalent to:
        # $merged_hash =  {'one' => 1, 'two' => 'dos', 'three' => 'tres'}

    When there is a duplicate key, the key in the rightmost hash will "win"; however if the key is an hash,
    it will be merged itself as well.

    ENDHEREDOC

    if args.length < 2
      raise Puppet::ParseError, ("merge(): wrong number of arguments (#{args.length}; must be at least 2)")
    end

    # The hash we accumulate into
    accumulator = Hash.new
    # Merge into the accumulator hash
    args.each do |arg|
      unless arg.is_a?(Hash)
        raise Puppet::ParseError, "merge: unexpected argument type #{arg.class}, only expects hash arguments"
      end
      accumulator.deep_merge(arg)
    end
    # Return the fully merged hash
    accumulator
  end
end
