require 'spec_helper'

describe 'wmflib::dirtree' do
  it { is_expected.to run.with_params('/').and_return([]) }
  it { is_expected.to run.with_params('/etc').and_return([]) }
  it { is_expected.to run.with_params('/etc/foo').and_return(['/etc']) }
  it do
    is_expected.to run.with_params('/etc/foo/bar/test.conf').and_return(
      ['/etc/foo/bar', '/etc/foo', '/etc']
    )
  end
  it do
    is_expected.to run.with_params('foo/bar/conf.text').and_raise_error(
      Puppet::ParseError, 'dirtree requires a fully qualified path'
    )
  end
end
