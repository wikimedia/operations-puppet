require_relative '../../../../rake_modules/spec_helper'

describe 'wmflib::dir::split' do
  it { is_expected.to run.with_params('/').and_return([]) }
  it { is_expected.to run.with_params('/etc').and_return(['/etc']) }
  it { is_expected.to run.with_params('/etc/foo').and_return(['/etc', '/etc/foo']) }
  it { is_expected.to run.with_params(['/etc/foo', '/foo']).and_return(['/etc', '/etc/foo', '/foo']) }
end
