require 'spec_helper'
describe 'role' do
  before :each do
    scope.stubs(:is_nodescope?).returns(true)
  end

  let(:pre_condition) {"
class role::test {}
class role::test::foo {
      if ($::_roles['test::foo']) { file { '/tmp/test': ensure => present} }
      file{ \"/tmp/${::_role}\": ensure => present}
}
"}
  it "should be called with one parameter" do
    should run.with_params.and_raise_error(ArgumentError)
  end

  it "throws error if called on a non-existing role" do
    is_expected.to run.with_params('foo::bar').and_raise_error(Puppet::Error)
  end

  it "includes the role class" do
    is_expected.to run.with_params('test')
    expect(catalogue).to contain_class('role::test')
  end

  it "adds the keys to the top-scope variables" do
    is_expected.to run.with_params('test::foo')
    expect(catalogue).to contain_file('/tmp/test')
    expect(catalogue).to contain_file('/tmp/test/foo')
  end

  context 'function has already been called' do
    let(:pre_condition) {"
class role::test {}
class role::test2 {}
role('test')
" }
    it "raises an error when called more than once in a scope" do
      is_expected.to run.with_params('test2').and_raise_error(Puppet::Error)
    end
  end
end
