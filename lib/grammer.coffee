
{Parser} = require 'jison'


unwrap = /^function\s*\(\)\s*\{\s*return\s*([\s\S]*);\s*\}/

o = (patternString, action, options) ->
  patternString = patternString.replace /\s{2,}/g, ' '
  return [patternString, '$$ = $1;', options] unless action
  action = if match = unwrap.exec action then match[1] else "(#{action}())"
  # action = action.replace /\bnew /g, '$&yy.'
  [patternString, "$$ = #{action};", options]

grammar = 

  Root: [
    o 'Query EOF'
  ]
  
  Query: [
    o "SelectQuery"
  ]
  
  SelectQuery: [
    o 'SelectFrom'
    o 'SelectFrom OrderClause', -> "#{$1} #{$2}"
    o 'SelectFrom GroupClause', -> "#{$1} #{$2}"
    o 'SelectFrom WhereClause GroupClause', -> "#{$1} #{$2} #{$3}"
    o 'SelectFrom WhereClause GroupClause OrderClause', -> "#{$1} #{$2} #{$3} #{$4}"
    o 'SelectFrom WhereClause', -> "#{$1} #{$2}"
    o 'SelectFrom WhereClause OrderClause', -> "#{$1} #{$2} #{$3}"
  ]
  
  SelectFrom: [
    o 'SELECT Fields FROM LITERAL', -> "#{$1} #{$2} #{$3} #{$4}"
  ]
  
  WhereClause: [
    o 'WHERE Conditions', -> "WHERE #{$2}"
  ]
  
  OrderClause: [
    o 'ORDER BY Value DIRECTION', -> "ORDER BY #{$3} #{$4}"
  ]
  
  GroupClause: [
    o 'GROUP BY ArgumentList', -> "GROUP BY #{$3}"
  ]
  
  Conditions: [
    o 'Condition'
    o 'Condition CONDITIONAL Condition', -> "#{$1} #{$2} #{$3}"
  ]
  
  Condition: [
    o 'Value OPERATOR Value', -> "#{$1} #{$2} #{$3}"
  ]
  
  Value: [
    o 'LITERAL'
    o 'NUMBER'
    o 'STRING'
    o 'Function'
  ]
  
  Function: [
    o "FUNCTION LEFT_PAREN ArgumentList RIGHT_PAREN", -> "#{$1}(#{$3})"
  ]
  
  ArgumentList: [
    o 'Value'
    o 'Value SEPARATOR ArgumentList', -> "#{$1}, #{$3}"
  ]
  
  Fields: [
    o 'Field'
    o 'Field SEPARATOR Fields', -> "#{$1}, #{$3}"
  ]
  
  Field: [
    o 'STAR'
    o 'Value'
    o 'Value AS LITERAL', -> "#{$1} AS #{$3}"
  ]



buildParser = ->
  tokens = []
  operators = []

  for name, alternatives of grammar
    grammar[name] = for alt in alternatives
      for token in alt[0].split ' '
        tokens.push token unless grammar[token]
      alt[1] = "return #{alt[1]}" if name is 'Root'
      alt
  
  parser = new Parser
    tokens      : tokens.join ' '
    bnf         : grammar
    operators   : operators.reverse()
    startSymbol : 'Root'

  parser.lexer =
    lex: ->
      [tag, @yytext, @yylineno] = @tokens[@pos++] or ['']
      tag
    setInput: (@tokens) ->
      @pos = 0
    upcomingInput: ->
      ""
  return parser
  
exports.parser = buildParser()