require_relative '../../../../rake_modules/spec_helper'

describe 'ipresolve' do
  it "should resolve ipv4 addresses by default" do
    should run.with_params('bast1003.wikimedia.org').and_return('208.80.155.110')
  end
  it "should resolve ipv4 addresses when explicitly asked to" do
    should run.with_params('bast1003.wikimedia.org', '4').and_return('208.80.155.110')
  end

  it "should resolve ipv6 addresses" do
    should run.with_params('bast1003.wikimedia.org', '6').and_return('2620:0:861:4:208:80:155:110')
  end

  it "should be able to perform a reverse DNS lookup" do
    should run.with_params('2620:0:861:4:208:80:155:110', 'ptr').and_return('bast1003.wikimedia.org')
    should run.with_params('208.80.155.110', 'ptr').and_return('bast1003.wikimedia.org')
  end

  it "fails when resolving an inexistent name" do
    # This will test if your ISP does DNS hijacking too
    should run.with_params('host.does.not.exists').and_raise_error(RuntimeError)
  end
end
