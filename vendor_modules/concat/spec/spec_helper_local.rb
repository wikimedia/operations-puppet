# frozen_string_literal: true

if ENV['COVERAGE'] == 'yes'
  require 'simplecov'
  require 'simplecov-console'
  require 'codecov'

  SimpleCov.formatters = [
    SimpleCov::Formatter::HTMLFormatter,
    SimpleCov::Formatter::Console,
    SimpleCov::Formatter::Codecov,
  ]
  SimpleCov.start do
    track_files 'lib/**/*.rb'

    add_filter '/spec'

    # do not track vendored files
    add_filter '/vendor'
    add_filter '/.vendor'

    # do not track gitignored files
    # this adds about 4 seconds to the coverage check
    # this could definitely be optimized
    add_filter do |f|
      # system returns true if exit status is 0, which with git-check-ignore means file is ignored
      system("git check-ignore --quiet #{f.filename}")
    end
  end
end

shared_examples 'Puppet::Parameter::Boolean' do |parameter|
  [true, :true, 'true', :yes, 'yes'].each do |value|
    it "accepts #{value} (#{value.class}) as a value" do
      resource[parameter] = value
      expect(resource[parameter]).to eq(true)
    end
  end

  [false, :false, 'false', :no, 'no'].each do |value|
    it "accepts #{value} (#{value.class}) as a value" do
      resource[parameter] = value
      expect(resource[parameter]).to eq(false)
    end
  end

  it 'does not accept "foo" as a value' do
    expect { resource[parameter] = 'foo' }.to raise_error(%r{Invalid value "foo"})
  end
end

shared_examples 'a parameter that accepts only string values' do |parameter|
  it 'accepts a string value' do
    resource[parameter] = 'foo'
    expect(resource[parameter]).to eq('foo')
  end

  it 'does not accept an array value' do
    expect { resource[parameter] = ['foo', 'bar'] }.to raise_error(%r{must be a String})
  end

  it 'does not accept a hash value' do
    expect { resource[parameter] = { foo: 'bar' } }.to raise_error(%r{must be a String})
  end

  it 'does not accept an integer value' do
    expect { resource[parameter] = 9001 }.to raise_error(%r{must be a String})
  end

  it 'does not accept a boolean true value' do
    expect { resource[parameter] = true }.to raise_error(%r{must be a String})
  end

  it 'does not accept a boolean false value' do
    expect { resource[parameter] = false }.to raise_error(%r{must be a String})
  end
end
