# vim: syntax=ruby


class PuppetDB::Parser

  token LPAREN RPAREN LBRACK RBRACK LBRACE RBRACE
  token EQUALS NOTEQUALS MATCH LESSTHAN GREATERTHAN
  token NOT AND OR
  token NUMBER STRING BOOLEAN EXPORTED

  prechigh
    right NOT
    left  EQUALS MATCH LESSTHAN GREATERTHAN
    left  AND
    left  OR
  preclow

rule
  query:
     |exp

  exp: LPAREN exp RPAREN			{ result = val[1] }
     | NOT exp					{ result = ASTNode.new :booleanop, :not, [val[1]] }
     | exp AND exp				{ result = ASTNode.new :booleanop, :and, [val[0], val[2]] }
     | exp OR exp				{ result = ASTNode.new :booleanop, :or, [val[0], val[2]] }
     | string EQUALS string			{ result = ASTNode.new :exp, :equals, [val[0], val[2]] }
     | string EQUALS boolean			{ result = ASTNode.new :exp, :equals, [val[0], val[2]] }
     | string EQUALS number			{ result = ASTNode.new :exp, :equals, [val[0], val[2]] }
     | string GREATERTHAN number		{ result = ASTNode.new :exp, :greaterthan, [val[0], val[2]] }
     | string LESSTHAN number			{ result = ASTNode.new :exp, :lessthan, [val[0], val[2]] }
     | string MATCH string			{ result = ASTNode.new :exp, :match, [val[0], val[2]] }
     | string NOTEQUALS number			{ result = ASTNode.new :booleanop, :not, [ASTNode.new(:exp, :equals, [val[0], val[2]])] }
     | string NOTEQUALS boolean			{ result = ASTNode.new :booleanop, :not, [ASTNode.new(:exp, :equals, [val[0], val[2]])] }
     | string NOTEQUALS string			{ result = ASTNode.new :booleanop, :not, [ASTNode.new(:exp, :equals, [val[0], val[2]])] }
     | ressubquery

  ressubquery: resexp				{ result = ASTNode.new :subquery, :resources, [ASTNode.new(:booleanop, :and, [ASTNode.new(:resexported, false), *val[0]])] }
             | resexported resexp	        { result = ASTNode.new :subquery, :resources, [ASTNode.new(:booleanop, :and, [ASTNode.new(:resexported, true), *val[1]])] }

  resexp: restype				{ result = [val[0]] }
        | restitle				{ result = [val[0]] }
        | resparams				{ result = [val[0]] }
        | restype restitle			{ result = val[0].value == "Class" ? [val[0], val[1].capitalize!] : [val[0], val[1]] }
        | restitle resparams			{ result = [val[0], val[1]] }
        | restype resparams			{ result = [val[0], val[1]] }
        | restype restitle resparams		{ result = val[0].value == "Class" ? [val[0], val[1].capitalize!, val[2]] : [val[0], val[1], val[2]] }

  resexported: EXPORTED
  restype: STRING				{ result = ASTNode.new(:resourcetype, val[0]).capitalize! }
  restitle: LBRACK STRING RBRACK		{ result = ASTNode.new :resourcetitle, '=', [ASTNode.new(:string, val[1])] }
  restitle: LBRACK MATCH STRING RBRACK		{ result = ASTNode.new :resourcetitle, '~', [ASTNode.new(:string, val[2])] }
  resparams: LBRACE exp RBRACE			{ result = val[1] }

  string: STRING				{ result = ASTNode.new :string, val[0] }
  number: NUMBER				{ result = ASTNode.new :number, val[0] }
  boolean: BOOLEAN				{ result = ASTNode.new :boolean, val[0] }

end
---- header ----
require 'puppetdb'
require 'puppetdb/lexer'
require 'puppetdb/astnode'
