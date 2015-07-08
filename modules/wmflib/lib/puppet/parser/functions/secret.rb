require 'pathname'

SECPATH = '/var/lib/git/operations/private/secrets'

module Puppet::Parser::Functions
  newfunction(:secret, :type => :rvalue) do |args|
    if args.length != 1 || !args.first.is_a?(String)
      fail(ArgumentError, 'secret(): exactly one string arg')
    end

    inpath = args.shift

    # This will do an in-memory (not looking at FS) cleanup of inpath,
    # including multiple slashes and ".."'.  Forcing it to look absolute with
    # a preprended '/' ensures all ".." are killed.
    inpath_clean = Pathname.new('/' + inpath).cleanpath().to_s()

    # Now combine with the root SECPATH for a real FS pathname
    final_path = Pathname.new(SECPATH + inpath_clean)

    # Bail early if it's not a regular, readable file
    if !final_path.file? || !final_path.readable?
      fail(ArgumentError, "secret(): invalid secret #{inpath_clean}")
    end

    return final_path.read()
  end
end
