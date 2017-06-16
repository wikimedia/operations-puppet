# == Function htpasswd( string $password, string $salt)
#
# Generate a password entry for a htpasswd file using the modified md5 digest
# method from apr.
#

require 'digest/md5'
require 'stringio'

# This class is a conversion to puppet of htauth's methods
# See https://github.com/copiousfreetime/htauth/blob/master/LICENSE for copying rights
# Original code Copyright (c) 2008 Jeremy Hinegardner
# Modifications Copyright (c) 2017 Giuseppe Lavagetto, Wikimedia Foundation, Inc.
class Apr1Md5
  DIGEST_LENGTH = 16

  def initialize(salt)
    @salt = salt
  end

  def prefix
    "$apr1$"
  end

  # from https://github.com/copiousfreetime/htauth/blob/master/lib/htauth/algorithm.rb
  # this is not the Base64 encoding, this is the to64() method from apr
  SALT_CHARS = (%w( . / ) + ("0".."9").to_a + ('A'..'Z').to_a + ('a'..'z').to_a).freeze
  def to_64(number, rounds)
    r = StringIO.new
    rounds.times do
      r.print(SALT_CHARS[number % 64])
      number >>= 6
    end
    r.string
  end

  # this algorithm pulled straight from apr_md5_encode() and converted to ruby syntax
  def encode(password)
    primary = ::Digest::MD5.new
    primary << password
    primary << prefix
    primary << @salt

    md5_t = ::Digest::MD5.digest("#{password}#{@salt}#{password}")

    l = password.length
    while l > 0
      slice_size = (l > DIGEST_LENGTH) ? DIGEST_LENGTH : l
      primary << md5_t[0, slice_size]
      l -= DIGEST_LENGTH
    end

    # weirdness
    l = password.length
    while l != 0
      case (l & 1)
      when 1
        primary << 0.chr
      when 0
        primary << password[0, 1]
      end
      l >>= 1
    end

    pd = primary.digest

    encoded_password = "#{prefix}#{@salt}$"

    # apr_md5_encode has this comment about a 60Mhz Pentium above this loop.
    1000.times do |x|
      ctx = ::Digest::MD5.new
      ctx << (((x & 1) == 1) ? password : pd[0, DIGEST_LENGTH])
      (ctx << @salt) unless (x % 3).zero?
      (ctx << password) unless (x % 7).zero?
      ctx << (((x & 1).zero?) ? password : pd[0, DIGEST_LENGTH])
      pd = ctx.digest
    end

    pd = pd.bytes.to_a

    l = (pd[0] << 16) | (pd[6] << 8) | pd[12]
    encoded_password << to_64(l, 4)

    l = (pd[1] << 16) | (pd[7] << 8) | pd[13]
    encoded_password << to_64(l, 4)

    l = (pd[2] << 16) | (pd[8] << 8) | pd[14]
    encoded_password << to_64(l, 4)

    l = (pd[3] << 16) | (pd[9] << 8) | pd[15]
    encoded_password << to_64(l, 4)

    l = (pd[4] << 16) | (pd[10] << 8) | pd[5]
    encoded_password << to_64(l, 4)
    encoded_password << to_64(pd[11], 2)

    encoded_password
  end
end

module Puppet::Parser::Functions
  newfunction(:htpasswd, :type => :rvalue, :arity => 2) do |args|
    generator = Apr1Md5.new args[1]
    generator.encode args[0]
  end
end
