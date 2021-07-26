require_relative '../../../../rake_modules/spec_helper'

describe 'wmflib::dir::mkdir_p' do
  it "with '/'" do
    is_expected.to run.with_params('/')
    expect(catalogue).to contain_file('/').with_ensure('directory')
  end
  it "with '/etc'" do
    is_expected.to run.with_params('/etc')
    expect(catalogue).not_to contain_file('/').with_ensure('directory')
    expect(catalogue).to contain_file('/etc').with_ensure('directory')
  end
  it "with '/etc/foo'" do
    is_expected.to run.with_params('/etc/foo')
    expect(catalogue).not_to contain_file('/').with_ensure('directory')
    expect(catalogue).to contain_file('/etc').with_ensure('directory')
    expect(catalogue).to contain_file('/etc/foo').with_ensure('directory')
  end
  it "with '/etc/foo', '/foo'" do
    is_expected.to run.with_params(['/etc/foo', '/foo'])
    expect(catalogue).not_to contain_file('/').with_ensure('directory')
    expect(catalogue).to contain_file('/etc').with_ensure('directory')
    expect(catalogue).to contain_file('/etc/foo').with_ensure('directory')
    expect(catalogue).to contain_file('/foo').with_ensure('directory')
  end
  it "with '/etc/foo', '/foo' and custom params" do
    is_expected.to run.with_params(['/etc/foo', '/foo'], {'owner' => 'foo', 'mode' => '0500'})
    expect(catalogue).not_to contain_file('/').with_ensure('directory')
    expect(catalogue).to contain_file('/etc')
      .with_ensure('directory')
      .without_owner
      .without_mode
    expect(catalogue).to contain_file('/etc/foo')
      .with_ensure('directory')
      .with_owner('foo')
      .with_mode('0500')
    expect(catalogue).to contain_file('/foo')
      .with_ensure('directory')
      .with_owner('foo')
      .with_mode('0500')
  end
  it "with '/etc/foo', '/foo' and custom params" do
    is_expected.to run.with_params(['/etc/foo', '/etc/bar'], {'owner' => 'foo', 'mode' => '0500'})
    expect(catalogue).not_to contain_file('/').with_ensure('directory')
    expect(catalogue).to contain_file('/etc')
      .with_ensure('directory')
      .without_owner
      .without_mode
    expect(catalogue).to contain_file('/etc/foo')
      .with_ensure('directory')
      .with_owner('foo')
      .with_mode('0500')
    expect(catalogue).to contain_file('/etc/bar')
      .with_ensure('directory')
      .with_owner('foo')
      .with_mode('0500')
  end
  it "with '/etc/foo', '//etc/bar' and custom params" do
    is_expected.to run.with_params('/etc/foo', {'owner' => 'foo', 'mode' => '0500'})
    is_expected.to run.with_params('/etc/bar', {'owner' => 'foo', 'mode' => '0500'})
    expect(catalogue).not_to contain_file('/').with_ensure('directory')
    expect(catalogue).to contain_file('/etc')
      .with_ensure('directory')
      .without_owner
      .without_mode
    expect(catalogue).to contain_file('/etc/foo')
      .with_ensure('directory')
      .with_owner('foo')
      .with_mode('0500')
    expect(catalogue).to contain_file('/etc/bar')
      .with_ensure('directory')
      .with_owner('foo')
      .with_mode('0500')
  end
end
