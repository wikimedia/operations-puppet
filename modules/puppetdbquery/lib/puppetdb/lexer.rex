# vim: syntax=ruby

require 'yaml'
require 'puppetdb'

class PuppetDB::Lexer
macro
STR        [\w_:]
rule
  \s                # whitespace no action
  \(                { [:LPAREN, text] }
  \)                { [:RPAREN, text] }
  \[                { [:LBRACK, text] }
  \]                { [:RBRACK, text] }
  \{                { [:LBRACE, text] }
  \}                { [:RBRACE, text] }
  =                 { [:EQUALS, text] }
  \!=               { [:NOTEQUALS, text] }
  ~                 { [:MATCH, text] }
  \!~               { [:NOTMATCH, text] }
  <=                { [:LESSTHANEQ, text] }
  <                 { [:LESSTHAN, text] }
  >=                { [:GREATERTHANEQ, text] }
  >                 { [:GREATERTHAN, text] }
  \*                { [:ASTERISK, text] }
  \#                { [:HASH, text] }
  \.                { [:DOT, text] }
  not(?!{STR})      { [:NOT, text] }
  and(?!{STR})      { [:AND, text] }
  or(?!{STR})       { [:OR, text] }
  true(?!{STR})     { [:BOOLEAN, true]}
  false(?!{STR})    { [:BOOLEAN, false]}
  -?\d+             { [:NUMBER, text.to_i] }
  \"(\\.|[^\\"])*\" { [:STRING, YAML.load(text)] }
  \'(\\.|[^\\'])*\' { [:STRING, YAML.load(text)] }
  {STR}+            { [:STRING, text] }
  @@                { [:EXPORTED, text] }
  @                 { [:AT, text] }
end
