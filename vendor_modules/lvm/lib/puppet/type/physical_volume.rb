# frozen_string_literal: true

require 'pathname'

Puppet::Type.newtype(:physical_volume) do
  desc 'Physical volume resource type'

  ensurable

  newparam(:name) do
    desc 'Resource name'
    isnamevar
    validate do |value|
      raise ArgumentError, 'Physical Volume names must be fully qualified' unless Pathname.new(value).absolute?
    end
  end

  newparam(:unless_vg) do
    desc "Do not do anything if the VG already exists.  The value should be the
              name of the volume group to check for."
    validate do |value|
      raise ArgumentError, "#{value} is not a valid volume group name" unless %r{^[0-9A-Z]}i.match?(value)
    end
  end

  newparam(:force) do
    desc 'Force the creation without any confirmation.'
    defaultto :false
    newvalues(:true, :false)
  end
end
