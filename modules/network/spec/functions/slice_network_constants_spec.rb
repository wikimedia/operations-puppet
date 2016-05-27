require 'spec_helper'

describe "slice_network_constants" do
  it "should exist" do
    expect(Puppet::Parser::Functions.function("slice_network_constants")).to eq "function_slice_network_constants"
  end

  before :each do
    @scope = Puppet::Parser::Scope
  end

  it "should raise a ParseError if there are less than 1 arguments" do
    expect { subject.call([]) }.to raise_error(ArgumentError)
  end

  it "should raise a ParseError if there are more than 2 arguments" do
    expect { subject.call(['a', 'b', 'c']) }.to raise_error(ArgumentError)
  end

  # Test realm
  it "should complain about invalid realm" do
    expect { subject.call(['nosuchrealm']) }.to raise_error(ArgumentError)
  end

  it "should return for valid realm" do
    result = subject.call(['production'])
    expect(result).to be_an Array
  end

  # Test site
  it "should complain about invalid site" do
    expect { subject.call(['production', { 'site' => 'nosuchsite'}])}.to raise_error(ArgumentError)
  end

  it "should return for valid site" do
    result = subject.call(['production', { 'site' => 'eqiad'}])
    expect(result).to be_an Array
    # TODO: After migrating to dummy data actually test this result for equality
  end

  # Test sphere
  it "should complain about invalid sphere" do
    expect{ subject.call(['production', { 'sphere' => 'nosuchsphere'}])}.to raise_error(ArgumentError)
  end

  it "should return for valid sphere" do
    result = subject.call(['production', { 'sphere' => 'public'}])
    expect(result).to be_an Array
    # TODO: After migrating to dummy data actually test this result for equality
  end

  # Test AF
  it "should complain about invalid af" do
    expect{ subject.call(['production', { 'af' => 'nosuchaf'}])}.to raise_error(ArgumentError)
  end

  it "should return for valid af" do
    result = subject.call(['production', { 'af' => 'ipv6'}])
    expect(result).to be_an Array
    # TODO: After migrating to dummy data actually test this result for equality
  end

  # Multiple together
  it "should return for valid site/af" do
    result = subject.call(['production', { 'site' => 'eqiad', 'af' => 'ipv6'}])
    expect(result).to be_an Array
    # TODO: After migrating to dummy data actually test this result for equality
  end
  it "should return for valid site/sphere" do
    result = subject.call(['production', { 'site' => 'eqiad', 'sphere' => 'public'}])
    expect(result).to be_an Array
    # TODO: After migrating to dummy data actually test this result for equality
  end
  it "should return for valid description" do
    result = subject.call(['production', { 'site' => 'eqiad', 'description' => 'analytics'}])
    expect(result).to be_an Array
    # TODO: After migrating to dummy data actually test this result for equality
  end
end
