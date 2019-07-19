require 'spec_helper'

notes_url_https = 'https://notes.example.org'
notes_url_http = 'http://notes.example.org'
notes_url_encode = 'https://notes.example.org/%20'
dashboard_links_https = ['https://dash.example.org/1', 'https://dash.example.org/2']
dashboard_links_http = ['http://dash.example.org']
dashboard_links_encode = ['https://dash.example.orgi/%20']

describe 'monitoring::build_notes_url' do
  it do
    is_expected.to run.with_params(notes_url_https, dashboard_links_https).and_return(
      "'#{notes_url_https}' '#{dashboard_links_https[0]}' '#{dashboard_links_https[1]}'"
    )
  end
  it do
    is_expected.to run.with_params(notes_url_https, [dashboard_links_https[0]]).and_return(
      "'#{notes_url_https}' '#{dashboard_links_https[0]}'"
    )
  end
  it do
    is_expected.to run.with_params(notes_url_https, []).and_return(
      "#{notes_url_https}"
    )
  end
  it do
    is_expected.to run.with_params(notes_url_http, dashboard_links_https).and_raise_error(
      ArgumentError, /expects a match for Stdlib::HTTPSUrl/
    )
  end
  it do
    is_expected.to run.with_params(notes_url_https, dashboard_links_http).and_raise_error(
      ArgumentError, /expects a match for Stdlib::HTTPSUrl/
    )
  end
  it do
    is_expected.to run.with_params(notes_url_encode, dashboard_links_https).and_raise_error(
      Puppet::ParseError, /The \$dashboard_links and \$notes_links URLs must not be URL-encoded/
    )
  end
  it do
    is_expected.to run.with_params(notes_url_https, dashboard_links_encode).and_raise_error(
      Puppet::ParseError, /The \$dashboard_links and \$notes_links URLs must not be URL-encoded/
    )
  end
end
