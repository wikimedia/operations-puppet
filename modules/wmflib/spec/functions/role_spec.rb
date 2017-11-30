require 'spec_helper'
describe 'role' do
  before :each do
    allow(scope).to receive(:is_nodescope?).and_return(true)
  end

  let(:pre_condition) {"
class role::test {}
class role::test2 {}
"}
  it "should be called with one parameter" do
    should run.with_params.and_raise_error(ArgumentError)
  end
  it "throws error if called outside of the node scope" do
    should run.with_params('cache::text').and_raise_error(Puppet::ParseError)
  end

  it "throws error if called on a non-existing role" do
    is_expected.to run.with_params('foo::bar').and_raise_error(Puppet::ParseError)
  end

  it "includes the role class" do
    is_expected.to run.with_params('test')
  end

  it "raises an error when called more than once in a scope" do
    scope.function_role(['test2'])
    expect { scope.function_role(['test']) }.to raise_error(Puppet::ParseError)
  end

  it "adds the keys to the top-scope variable" do
    scope.function_role(['test', 'test2'])
    expect(scope.lookupvar('_roles')).to eq({'test' => true, 'test2' => true})
  end

  it "includes the role classes" do
    scope.function_role(['test'])
    expect(scope.find_hostclass('role::test')).to be_an_instance_of(Puppet::Resource::Type)
  end
end
