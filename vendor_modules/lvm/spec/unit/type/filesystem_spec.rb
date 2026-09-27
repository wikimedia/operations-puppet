# frozen_string_literal: true

require 'spec_helper'

describe Puppet::Type.type(:filesystem) do
  it 'raises an ArgumentError when the name is not an absolute path' do
    expect {
      resource = Puppet::Type.type(:filesystem).new(
        name: 'notAnAbsolutePath',
        ensure: :present,
        fs_type: 'ext3',
        options: '-b 4096 -E stride=32,stripe-width=64',
      )
    }.to raise_error(Puppet::ResourceError,
                     'Parameter name failed on Filesystem[notAnAbsolutePath]: Filesystem names must be fully qualified')
  end

  it 'does not raise an ArgumentError when the name is an absolute path' do
    expect {
      resource = Puppet::Type.type(:filesystem).new(
        name: '/dev/myvg/mylv',
        ensure: :present,
        fs_type: 'ext3',
        options: '-b 4096 -E stride=32,stripe-width=64',
      )
    }.not_to raise_error
  end
end
