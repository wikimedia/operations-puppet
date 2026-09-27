# frozen_string_literal: true

require 'spec_helper'

describe Puppet::Type.type(:logical_volume) do
  it 'raises an ArgumentError when the name has a file separator' do
    expect {
      resource = Puppet::Type.type(:logical_volume).new(
        name: '/dev/lol',
        ensure: :present,
        volume_group: 'myvg',
        size: '20G',
      )
    }.to raise_error(Puppet::ResourceError,
                     'Parameter name failed on Logical_volume[/dev/lol]: Volume names must be entirely unqualified')
  end

  it 'does not raise an ArgumentError when the name has no file separator' do
    expect {
      resource = Puppet::Type.type(:logical_volume).new(
        name: 'myvg',
        ensure: :present,
        volume_group: 'myvg',
        size: '20G',
      )
    }.not_to raise_error
  end

  it 'invalid logical initial volume size raises error (char)' do
    expect {
      resource = Puppet::Type.type(:logical_volume).new(
        name: 'myvg',
        ensure: :present,
        volume_group: 'myvg',
        initial_size: 'abcd',
      )
    }.to raise_error(Puppet::ResourceError,
                     'Parameter initial_size failed on Logical_volume[myvg]: abcd is not a valid logical volume size')
  end

  it 'invalid logical initial volume size raises error (suffix)' do
    expect {
      resource = Puppet::Type.type(:logical_volume).new(
        name: 'myvg',
        ensure: :present,
        volume_group: 'myvg',
        initial_size: '20A',
      )
    }.to raise_error(Puppet::ResourceError,
                     'Parameter initial_size failed on Logical_volume[myvg]: 20A is not a valid logical volume size')
  end

  it 'valid logical volume initial size does not raise error' do
    expect {
      resource = Puppet::Type.type(:logical_volume).new(
        name: 'myvg',
        ensure: :present,
        volume_group: 'myvg',
        initial_size: '20G',
      )
    }.not_to raise_error
  end

  it 'invalid logical volume size raises error (char)' do
    expect {
      resource = Puppet::Type.type(:logical_volume).new(
        name: 'myvg',
        ensure: :present,
        volume_group: 'myvg',
        size: 'lucy<3',
      )
    }.to raise_error(Puppet::ResourceError,
                     'Parameter size failed on Logical_volume[myvg]: lucy<3 is not a valid logical volume size')
  end

  it 'invalid logical volume size raises error (suffix)' do
    expect {
      resource = Puppet::Type.type(:logical_volume).new(
        name: 'myvg',
        ensure: :present,
        volume_group: 'myvg',
        size: '20Q',
      )
    }.to raise_error(Puppet::ResourceError,
                     'Parameter size failed on Logical_volume[myvg]: 20Q is not a valid logical volume size')
  end

  it 'invalid logical volume extent raises error' do
    expect {
      resource = Puppet::Type.type(:logical_volume).new(
        name: 'zerocool',
        ensure: :present,
        volume_group: 'myvg',
        size: '10M',
        extents: 'acidburn',
      )
    }.to raise_error(Puppet::ResourceError,
                     'Parameter extents failed on Logical_volume[zerocool]: acidburn is not a valid logical volume extent')
  end

  it 'valid logical volume extent does not raise error' do
    expect {
      resource = Puppet::Type.type(:logical_volume).new(
        name: 'zerocool',
        ensure: :present,
        volume_group: 'myvg',
        size: '10M',
        extents: '1%vg',
      )
    }.not_to raise_error
  end

  it 'persistent which is not true or false raises error' do
    expect {
      resource = Puppet::Type.type(:logical_volume).new(
        name: 'simba',
        ensure: :present,
        volume_group: 'rafiki',
        size: '10M',
        persistent: 'nala',
      )
    }.to raise_error(Puppet::ResourceError,
                     'Parameter persistent failed on Logical_volume[simba]: persistent must be either be true or false')
  end

  it 'persistent is true does not raise error' do
    expect {
      resource = Puppet::Type.type(:logical_volume).new(
        name: 'simba',
        ensure: :present,
        volume_group: 'rafiki',
        size: '10M',
        persistent: :true,
      )
    }.not_to raise_error
  end

  it 'minor not set to integer between 0 and 255 raises error' do
    expect {
      resource = Puppet::Type.type(:logical_volume).new(
        name: 'ringo',
        ensure: :present,
        volume_group: 'george',
        size: '10M',
        minor: '910',
      )
    }.to raise_error(Puppet::ResourceError,
                     'Parameter minor failed on Logical_volume[ringo]: 910 is not a valid value for minor. It must be an integer between 0 and 255')
  end

  it 'minor set to integer between 0 and 255 does not raise error' do
    expect {
      resource = Puppet::Type.type(:logical_volume).new(
        name: 'ringo',
        ensure: :present,
        volume_group: 'george',
        size: '10M',
        minor: '1',
      )
    }.not_to raise_error
  end

  it 'range set outside of valid range raises error' do
    expect {
      resource = Puppet::Type.type(:logical_volume).new(
        name: 'john',
        ensure: :present,
        volume_group: 'paul',
        size: '10M',
        range: 'pete best',
      )
    }.to raise_error(Puppet::ResourceError,
                     'Parameter range failed on Logical_volume[john]: pete best is not a valid range')
  end

  it 'range set within valid range does not raise error' do
    expect {
      resource = Puppet::Type.type(:logical_volume).new(
        name: 'john',
        ensure: :present,
        volume_group: 'paul',
        size: '10M',
        range: 'minimum',
      )
    }.not_to raise_error
  end

  it 'invalid number of stripes raises error' do
    expect {
      resource = Puppet::Type.type(:logical_volume).new(
        name: 'bert',
        ensure: :present,
        volume_group: 'ernie',
        size: '10M',
        stripes: 'rubber duckie',
      )
    }.to raise_error(Puppet::ResourceError,
                     'Parameter stripes failed on Logical_volume[bert]: rubber duckie is not a valid stripe count')
  end

  it 'number of stripes which is a positive integer does not raise error' do
    expect {
      resource = Puppet::Type.type(:logical_volume).new(
        name: 'big bird',
        ensure: :present,
        volume_group: 'elmo',
        size: '10M',
        stripes: '7',
      )
    }.not_to raise_error
  end

  it 'string stripesize raises error' do
    expect {
      resource = Puppet::Type.type(:logical_volume).new(
        name: 'bert',
        ensure: :present,
        volume_group: 'ernie',
        size: '10M',
        stripesize: 'rubber duckie',
      )
    }.to raise_error(Puppet::ResourceError,
                     'Parameter stripesize failed on Logical_volume[bert]: rubber duckie is not a valid stripesize')
  end

  it 'invalid stripesize raises error' do
    expect {
      resource = Puppet::Type.type(:logical_volume).new(
        name: 'bert',
        ensure: :present,
        volume_group: 'ernie',
        size: '10M',
        stripesize: '7+',
      )
    }.to raise_error(Puppet::ResourceError,
                     'Parameter stripesize failed on Logical_volume[bert]: 7+ is not a valid stripesize')
  end

  it 'valid stripesize does not raise error' do
    expect {
      resource = Puppet::Type.type(:logical_volume).new(
        name: 'big bird',
        ensure: :present,
        volume_group: 'elmo',
        size: '10M',
        stripesize: '7',
      )
    }.not_to raise_error
  end

  it 'valid, unstringified stripesize does not raise error' do
    expect {
      resource = Puppet::Type.type(:logical_volume).new(
        name: 'big bird',
        ensure: :present,
        volume_group: 'elmo',
        size: '10M',
        stripesize: 7,
      )
    }.not_to raise_error
  end

  it 'string readahead raises error' do
    expect {
      resource = Puppet::Type.type(:logical_volume).new(
        name: 'bert',
        ensure: :present,
        volume_group: 'ernie',
        size: '10M',
        readahead: 'cookie monster',
      )
    }.to raise_error(Puppet::ResourceError,
                     'Parameter readahead failed on Logical_volume[bert]: cookie monster is not a valid readahead count')
  end

  it 'valid readahead does not raise error' do
    expect {
      resource = Puppet::Type.type(:logical_volume).new(
        name: 'bert',
        ensure: :present,
        volume_group: 'ernie',
        size: '10M',
        readahead: '7Auto',
      )
    }.not_to raise_error
  end

  it 'size is minsize raises error if not a boolean' do
    expect {
      resource = Puppet::Type.type(:logical_volume).new(
        name: 'kuzco',
        ensure: :present,
        volume_group: 'kronk',
        size: '10M',
        size_is_minsize: 'pacha',
      )
    }.to raise_error(Puppet::ResourceError,
                     'Parameter size_is_minsize failed on Logical_volume[kuzco]: size_is_minsize must either be true or false')
  end

  it 'size is minsize does not raise error if boolean' do
    expect {
      resource = Puppet::Type.type(:logical_volume).new(
        name: 'kuzco',
        ensure: :present,
        volume_group: 'kronk',
        size: '10M',
        size_is_minsize: 'true',
      )
    }.not_to raise_error
  end

  it 'mirror number outside of 0-4 range throws error' do
    expect {
      resource = Puppet::Type.type(:logical_volume).new(
        name: 'scooby doo',
        ensure: :present,
        volume_group: 'shaggy',
        size: '10M',
        mirror: '-1',
      )
    }.to raise_error(Puppet::ResourceError,
                     'Parameter mirror failed on Logical_volume[scooby doo]: -1 is not a valid number of mirror copies. Use 0 to un-mirror or 1-4 to set up mirroring.')
  end

  it 'mirror within 0-4 range does not throw error' do
    expect {
      resource = Puppet::Type.type(:logical_volume).new(
        name: 'fred',
        ensure: :present,
        volume_group: 'daphne',
        size: '10M',
        mirror: '1',
      )
    }.not_to raise_error
  end

  it 'region_size with string value throws error' do
    expect {
      resource = Puppet::Type.type(:logical_volume).new(
        name: 'fred',
        ensure: :present,
        volume_group: 'daphne',
        size: '10M',
        region_size: 'velma',
      )
    }.to raise_error(Puppet::ResourceError,
                     'Parameter region_size failed on Logical_volume[fred]: velma is not a valid region size in MB.')
  end

  it 'region_size with invalid value throws error' do
    expect {
      resource = Puppet::Type.type(:logical_volume).new(
        name: 'fred',
        ensure: :present,
        volume_group: 'daphne',
        size: '10M',
        region_size: '7+',
      )
    }.to raise_error(Puppet::ResourceError,
                     'Parameter region_size failed on Logical_volume[fred]: 7+ is not a valid region size in MB.')
  end

  it 'region_size set to positive integer does not throw error' do
    expect {
      resource = Puppet::Type.type(:logical_volume).new(
        name: 'fred',
        ensure: :present,
        volume_group: 'daphne',
        size: '10M',
        region_size: '910',
      )
    }.not_to raise_error
  end
end
