#! /usr/bin/env ruby -S rspec

require 'spec_helper'
require 'puppetdb/parser'

describe PuppetDB::Parser do
  context 'Query parsing' do
    let(:parser) { PuppetDB::Parser.new }
    it 'should handle empty queries' do
      expect(parser.parse('')).to be_nil
    end

    it 'should handle double quoted strings' do
      expect(parser.parse('foo="bar"')).to eq \
        ['in', 'certname',
         ['extract', 'certname',
          ['select_fact_contents',
           ['and',
            ['=', 'path', ['foo']],
            ['=', 'value', 'bar']]]]]
    end

    it 'should handle single quoted strings' do
      expect(parser.parse('foo=\'bar\'')).to eq \
        ['in', 'certname',
         ['extract', 'certname',
          ['select_fact_contents',
           ['and',
            ['=', 'path', ['foo']],
            ['=', 'value', 'bar']]]]]
    end

    it 'should handle = operator' do
      expect(parser.parse('foo=bar')).to eq \
        ['in', 'certname',
         ['extract', 'certname',
          ['select_fact_contents',
           ['and',
            ['=', 'path', ['foo']],
            ['=', 'value', 'bar']]]]]
    end

    it 'should handle != operator' do
      expect(parser.parse('foo!=bar')).to eq \
        ['in', 'certname',
         ['extract', 'certname',
          ['select_fact_contents',
           ['and',
            ['=', 'path', ['foo']],
            ['not', ['=', 'value', 'bar']]]]]]
    end

    it 'should handle ~ operator' do
      expect(parser.parse('foo~bar')).to eq \
        ['in', 'certname',
         ['extract', 'certname',
          ['select_fact_contents',
           ['and',
            ['=', 'path', ['foo']],
            ['~', 'value', 'bar']]]]]
    end

    it 'should handle !~ operator' do
      expect(parser.parse('foo!~bar')).to eq \
        ['in', 'certname',
         ['extract', 'certname',
          ['select_fact_contents',
           ['and',
            ['=', 'path', ['foo']],
            ['not', ['~', 'value', 'bar']]]]]]
    end

    it 'should handle >= operator' do
      expect(parser.parse('foo>=1')).to eq \
        ['in', 'certname',
         ['extract', 'certname',
          ['select_fact_contents',
           ['and',
            ['=', 'path', ['foo']],
            ['>=', 'value', 1]]]]]
    end

    it 'should handle <= operator' do
      expect(parser.parse('foo<=1')).to eq \
        ['in', 'certname',
         ['extract', 'certname',
          ['select_fact_contents',
           ['and',
            ['=', 'path', ['foo']],
            ['<=', 'value', 1]]]]]
    end

    it 'should handle > operator' do
      expect(parser.parse('foo>1')).to eq \
        ['in', 'certname',
         ['extract', 'certname',
          ['select_fact_contents',
           ['and',
            ['=', 'path', ['foo']],
            ['>', 'value', 1]]]]]
    end

    it 'should handle < operator' do
      expect(parser.parse('foo<1')).to eq \
        ['in', 'certname',
         ['extract', 'certname',
          ['select_fact_contents',
           ['and',
            ['=', 'path', ['foo']],
            ['<', 'value', 1]]]]]
    end

    it 'should handle precedence' do
      expect(parser.parse 'foo=1 or bar=2 and baz=3').to eq ['or', ['in', 'certname', ['extract', 'certname', ['select_fact_contents', ['and', ['=', 'path', ['foo']], ['=', 'value', 1]]]]], ['and', ['in', 'certname', ['extract', 'certname', ['select_fact_contents', ['and', ['=', 'path', ['bar']], ['=', 'value', 2]]]]], ['in', 'certname', ['extract', 'certname', ['select_fact_contents', ['and', ['=', 'path', ['baz']], ['=', 'value', 3]]]]]]]
      expect(parser.parse '(foo=1 or bar=2) and baz=3').to eq ['and', ['or', ['in', 'certname', ['extract', 'certname', ['select_fact_contents', ['and', ['=', 'path', ['foo']], ['=', 'value', 1]]]]], ['in', 'certname', ['extract', 'certname', ['select_fact_contents', ['and', ['=', 'path', ['bar']], ['=', 'value', 2]]]]]], ['in', 'certname', ['extract', 'certname', ['select_fact_contents', ['and', ['=', 'path', ['baz']], ['=', 'value', 3]]]]]]
    end

    it 'should parse resource queries for exported resources' do
      expect(parser.parse '@@file[foo]').to eq ['in', 'certname', ['extract', 'certname', ['select_resources', ['and', ['=', 'type', 'File'], ['=', 'title', 'foo'], ['=', 'exported', true]]]]]
    end

    it 'should parse resource queries with type, title and parameters' do
      expect(parser.parse('file[foo]{bar=baz}')).to eq ['in', 'certname', ['extract', 'certname', ['select_resources', ['and', ['=', 'type', 'File'], ['=', 'title', 'foo'], ['=', 'exported', false], ['=', %w(parameter bar), 'baz']]]]]
    end

    it 'should parse resource queries with tags' do
      expect(parser.parse('file[foo]{tag=baz}')).to eq ['in', 'certname', ['extract', 'certname', ['select_resources', ['and', ['=', 'type', 'File'], ['=', 'title', 'foo'], ['=', 'exported', false], ['=', 'tag', 'baz']]]]]
    end

    it 'should handle precedence within resource parameter queries' do
      expect(parser.parse('file[foo]{foo=1 or bar=2 and baz=3}')).to eq ['in', 'certname', ['extract', 'certname', ['select_resources', ['and', ['=', 'type', 'File'], ['=', 'title', 'foo'], ['=', 'exported', false], ['or', ['=', %w(parameter foo), 1], ['and', ['=', %w(parameter bar), 2], ['=', %w(parameter baz), 3]]]]]]]
      expect(parser.parse('file[foo]{(foo=1 or bar=2) and baz=3}')).to eq ['in', 'certname', ['extract', 'certname', ['select_resources', ['and', ['=', 'type', 'File'], ['=', 'title', 'foo'], ['=', 'exported', false], ['and', ['or', ['=', %w(parameter foo), 1], ['=', %w(parameter bar), 2]], ['=', %w(parameter baz), 3]]]]]]
    end

    it 'should capitalize class names' do
      expect(parser.parse('class[foo::bar]')).to eq ['in', 'certname', ['extract', 'certname', ['select_resources', ['and', ['=', 'type', 'Class'], ['=', 'title', 'Foo::Bar'], ['=', 'exported', false]]]]]
    end

    it 'should parse resource queries with regeexp title matching' do
      expect(parser.parse('class[~foo]')).to eq ['in', 'certname', ['extract', 'certname', ['select_resources', ['and', ['=', 'type', 'Class'], ['~', 'title', 'foo'], ['=', 'exported', false]]]]]
    end

    it 'should be able to negate expressions' do
      expect(parser.parse('not foo=bar')).to eq ['not', ['in', 'certname', ['extract', 'certname', ['select_fact_contents', ['and', ['=', 'path', ['foo']], ['=', 'value', 'bar']]]]]]
    end

    it 'should handle single string expressions' do
      expect(parser.parse('foo.bar.com')).to eq ['~', 'certname', 'foo\\.bar\\.com']
    end

    it 'should handle structured facts' do
      expect(parser.parse('foo.bar=baz')).to eq ['in', 'certname', ['extract', 'certname', ['select_fact_contents', ['and', ['=', 'path', %w(foo bar)], ['=', 'value', 'baz']]]]]
    end

    it 'should handle structured facts with array component' do
      expect(parser.parse('foo.bar.0=baz')).to eq ['in', 'certname', ['extract', 'certname', ['select_fact_contents', ['and', ['=', 'path', ['foo', 'bar', 0]], ['=', 'value', 'baz']]]]]
    end

    it 'should handle structured facts with match operator' do
      expect(parser.parse('foo.bar.~".*"=baz')).to eq ['in', 'certname', ['extract', 'certname', ['select_fact_contents', ['and', ['~>', 'path', ['foo', 'bar', '.*']], ['=', 'value', 'baz']]]]]
    end

    it 'should handle structured facts with wildcard operator' do
      expect(parser.parse('foo.bar.*=baz')).to eq ['in', 'certname', ['extract', 'certname', ['select_fact_contents', ['and', ['~>', 'path', ['foo', 'bar', '.*']], ['=', 'value', 'baz']]]]]
    end

    it 'should handle #node subqueries' do
      expect(parser.parse('#node.catalog_environment=production')).to eq ['in', 'certname', ['extract', 'certname', ['select_nodes', ['=', 'catalog_environment', 'production']]]]
    end

    it 'should handle #node subqueries with block of conditions' do
      expect(parser.parse('#node { catalog_environment=production }')).to eq ['in', 'certname', ['extract', 'certname', ['select_nodes', ['=', 'catalog_environment', 'production']]]]
    end

    it 'should handle #node subquery combined with fact query' do
      expect(parser.parse('#node.catalog_environment=production and foo=bar')).to eq ['and', ['in', 'certname', ['extract', 'certname', ['select_nodes', ['=', 'catalog_environment', 'production']]]], ['in', 'certname', ['extract', 'certname', ['select_fact_contents', ['and', ['=', 'path', ['foo']], ['=', 'value', 'bar']]]]]]
    end

    it 'should escape non match parts on structured facts with match operator' do
      expect(parser.parse('"foo.bar".~".*"=baz')).to eq ['in', 'certname', ['extract', 'certname', ['select_fact_contents', ['and', ['~>', 'path', ['foo\\.bar', '.*']], ['=', 'value', 'baz']]]]]
    end

    it 'should parse dates in queries' do
      date = Time.new(2014, 9, 9).utc.strftime('%FT%TZ')
      expect(parser.parse('#node.report_timestamp<@"Sep 9, 2014"')).to eq ['in', 'certname', ['extract', 'certname', ['select_nodes', ['<', 'report_timestamp', date]]]]
    end

    it 'should not wrap it in a subquery if mode is :none' do
      expect(parser.parse 'class[apache]', :none).to eq ["and", ["=", "type", "Class"], ["=", "title", "Apache"], ["=", "exported", false]]
    end
  end

  context 'facts_query' do
    let(:parser) { PuppetDB::Parser.new }
    it 'should return a query for all if no facts are specified' do
      expect(parser.facts_query 'kernel=Linux').to eq ['in', 'certname', ['extract', 'certname', ['select_fact_contents', ['and', ['=', 'path', ['kernel']], ['=', 'value', 'Linux']]]]]
    end

    it 'should return a query for specific facts if they are specified' do
      expect(parser.facts_query 'kernel=Linux', ['ipaddress']).to eq ['and', ['in', 'certname', ['extract', 'certname', ['select_fact_contents', ['and', ['=', 'path', ['kernel']], ['=', 'value', 'Linux']]]]], ['or', ['=', 'name', 'ipaddress']]]
    end

    it 'should return a query for matching facts on all nodes if query is missing' do
      expect(parser.facts_query('', ['ipaddress'])).to eq ['or', ['=', 'name', 'ipaddress']]
    end
  end

  context 'facts_hash' do
    let(:parser) { PuppetDB::Parser.new }
    it 'should merge facts into a nested hash' do
      expect(parser.facts_hash([
        { 'certname' => 'ip-172-31-45-32.eu-west-1.compute.internal', 'environment' => 'production', 'name' => 'kernel', 'value' => 'Linux' },
        { 'certname' => 'ip-172-31-33-234.eu-west-1.compute.internal', 'environment' => 'production', 'name' => 'kernel', 'value' => 'Linux' },
        { 'certname' => 'ip-172-31-5-147.eu-west-1.compute.internal', 'environment' => 'production', 'name' => 'kernel', 'value' => 'Linux' },
        { 'certname' => 'ip-172-31-45-32.eu-west-1.compute.internal', 'environment' => 'production', 'name' => 'fqdn', 'value' => 'ip-172-31-45-32.eu-west-1.compute.internal' },
        { 'certname' => 'ip-172-31-33-234.eu-west-1.compute.internal', 'environment' => 'production', 'name' => 'fqdn', 'value' => 'ip-172-31-33-234.eu-west-1.compute.internal' },
        { 'certname' => 'ip-172-31-5-147.eu-west-1.compute.internal', 'environment' => 'production', 'name' => 'fqdn', 'value' => 'ip-172-31-5-147.eu-west-1.compute.internal' }
      ], ['kernel', 'fqdn'])).to eq(
        'ip-172-31-45-32.eu-west-1.compute.internal' => { 'kernel' => 'Linux', 'fqdn' => 'ip-172-31-45-32.eu-west-1.compute.internal' },
        'ip-172-31-33-234.eu-west-1.compute.internal' => { 'kernel' => 'Linux', 'fqdn' => 'ip-172-31-33-234.eu-west-1.compute.internal' },
        'ip-172-31-5-147.eu-west-1.compute.internal' => { 'kernel' => 'Linux', 'fqdn' => 'ip-172-31-5-147.eu-west-1.compute.internal' }
      )
    end

    it 'should handle nested facts' do
      expect(parser.facts_hash([
        { 'certname' => 'ip-172-31-45-32.eu-west-1.compute.internal', 'environment' => 'production', 'name' => 'kernel', 'value' => 'Linux' },
        { 'certname' => 'ip-172-31-33-234.eu-west-1.compute.internal', 'environment' => 'production', 'name' => 'kernel', 'value' => 'Linux' },
        { 'certname' => 'ip-172-31-45-32.eu-west-1.compute.internal', 'environment' => 'production', 'name' => 'networking', 'value' => { 'interfaces' => { 'eth0' => { 'ip' => '172.31.45.32' } } } },
        { 'certname' => 'ip-172-31-33-234.eu-west-1.compute.internal', 'environment' => 'production', 'name' => 'networking', 'value' => { 'interfaces' => { 'eth0' => { 'ip' => '172.31.33.234' } } } },
      ], ['kernel', ['networking', 'interfaces', 'eth0', 'ip']])).to eq(
        'ip-172-31-45-32.eu-west-1.compute.internal' => { 'kernel' => 'Linux', 'networking_interfaces_eth0_ip' => '172.31.45.32' },
        'ip-172-31-33-234.eu-west-1.compute.internal' => { 'kernel' => 'Linux', 'networking_interfaces_eth0_ip' => '172.31.33.234' },
      )
    end
  end

  context 'extract' do
    it 'should create an extract query' do
      expect(PuppetDB::ParserHelper.extract(:certname, :name, ['=', 'certname', 'foo.example.com'])).to eq(
        ['extract', ['certname', 'name'], ['=', 'certname', 'foo.example.com']]
      )
    end
  end
end
