require_relative '../../../../rake_modules/spec_helper'

describe 'wmflib::dir::mkdir_p' do
  it "with '/'" do
    is_expected.to run.with_params('/')
    expect(catalogue).to contain_file('/').with_ensure('directory')
  end
  # check whether we rmove FHS dirs
  it "with '/etc/foo'" do
    is_expected.to run.with_params('/etc/foo')
    expect(catalogue).not_to contain_file('/').with_ensure('directory')
    expect(catalogue).not_to contain_file('/etc').with_ensure('directory')
    expect(catalogue).to contain_file('/etc/foo').with_ensure('directory')
  end
  it "with '/baz'" do
    is_expected.to run.with_params('/baz')
    expect(catalogue).not_to contain_file('/').with_ensure('directory')
    expect(catalogue).to contain_file('/baz').with_ensure('directory')
  end
  it "with '/baz/foo'" do
    is_expected.to run.with_params('/baz/foo')
    expect(catalogue).not_to contain_file('/').with_ensure('directory')
    expect(catalogue).to contain_file('/baz').with_ensure('directory')
    expect(catalogue).to contain_file('/baz/foo').with_ensure('directory')
  end
  it "with '/baz/foo/'" do
    is_expected.to run.with_params('/baz/foo/', {'owner' => 'foo'})
    expect(catalogue).not_to contain_file('/').with_ensure('directory')
    expect(catalogue).to contain_file('/baz').with_ensure('directory').without_owner
    expect(catalogue).to contain_file('/baz/foo').with_ensure('directory').with_owner('foo')
  end
  it "with '/baz/foo', '/foo'" do
    is_expected.to run.with_params(['/baz/foo', '/foo'])
    expect(catalogue).not_to contain_file('/').with_ensure('directory')
    expect(catalogue).to contain_file('/baz').with_ensure('directory')
    expect(catalogue).to contain_file('/baz/foo').with_ensure('directory')
    expect(catalogue).to contain_file('/foo').with_ensure('directory')
  end
  it "with '/baz/foo', '/foo' and custom params" do
    is_expected.to run.with_params(['/baz/foo', '/foo'], {'owner' => 'foo', 'mode' => '0500'})
    expect(catalogue).not_to contain_file('/').with_ensure('directory')
    expect(catalogue).to contain_file('/baz')
      .with_ensure('directory')
      .without_owner
      .without_mode
    expect(catalogue).to contain_file('/baz/foo')
      .with_ensure('directory')
      .with_owner('foo')
      .with_mode('0500')
    expect(catalogue).to contain_file('/foo')
      .with_ensure('directory')
      .with_owner('foo')
      .with_mode('0500')
  end
  it "with '/baz/foo', '/baz/bar/' and custom params" do
    is_expected.to run.with_params(['/baz/foo', '/baz/bar/'], {'owner' => 'foo', 'mode' => '0500'})
    expect(catalogue).not_to contain_file('/').with_ensure('directory')
    expect(catalogue).to contain_file('/baz')
      .with_ensure('directory')
      .without_owner
      .without_mode
    expect(catalogue).to contain_file('/baz/foo')
      .with_ensure('directory')
      .with_owner('foo')
      .with_mode('0500')
    expect(catalogue).to contain_file('/baz/bar')
      .with_ensure('directory')
      .with_owner('foo')
      .with_mode('0500')
  end
  it "with '/baz/foo', '//baz/bar' and custom params" do
    is_expected.to run.with_params('/baz/foo', {'owner' => 'foo', 'mode' => '0500'})
    is_expected.to run.with_params('/baz/bar', {'owner' => 'foo', 'mode' => '0500'})
    expect(catalogue).not_to contain_file('/').with_ensure('directory')
    expect(catalogue).to contain_file('/baz')
      .with_ensure('directory')
      .without_owner
      .without_mode
    expect(catalogue).to contain_file('/baz/foo')
      .with_ensure('directory')
      .with_owner('foo')
      .with_mode('0500')
    expect(catalogue).to contain_file('/baz/bar')
      .with_ensure('directory')
      .with_owner('foo')
      .with_mode('0500')
  end
end
