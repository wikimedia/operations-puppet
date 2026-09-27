# frozen_string_literal: true

module Helpers
  TEST_DIR = "#{Pathname.new(__FILE__).parent}..".freeze

  TYPES = {
    pv: :physical_volume,
    lv: :logical_volume,
    vg: :volume_group,
    fs: :filesystem
  }.freeze

  def self.included(obj)
    obj.instance_eval { attr_reader :valid_params }
  end

  # Creates a new resource of +type+
  def with(opts = {}, &block)
    resource = @type.new(opts)
    block ? (yield resource) : resource
  end

  # Returns a lambda creating a resource (ready for use with +should+)
  def specifying(opts = {}, &block)
    specification = -> { with(opts) }
    block ? (yield specification) : specification
  end

  # Sets up an expection that a resource for +type+ is not created
  def should_not_create(type)
    raise "Invalid type #{type}" unless TYPES[type]

    Puppet::Type.type(TYPES[type]).expects(:new).never
  end

  # Sets up an expection that a resource for +type+ is created
  def should_create(type, &block)
    raise "Invalid type #{type}" unless TYPES[type]

    Puppet::Type.type(TYPES[type]).expects(:new).with(&block)
  end

  # Return the +@valid_params+ without one or more keys
  # Note: Useful since resource types don't like it when +nil+ is
  # passed as a parameter value
  def valid_params_without(*keys)
    valid_params.reject { |k, _v| keys.include?(k) }
  end

  # Stub the default provider to get around confines for testing
  def stub_default_provider!
    raise ArgumentError, '@type must be set' unless defined?(@type)

    provider = @type.provider(:lvm)
    @type.stubs(defaultprovider: provider)
  end

  def fixture(name, ext = '.txt')
    "#{TEST_DIR}fixtures#{name}#{ext}".read
  end
end
