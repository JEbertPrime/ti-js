// ti-basic grammar
// ================

{
  const types = require ('../common/types');
  const util = require ('./pegutil');
}

Start
  = Statement

// ----- Components -----

SourceCharacter
  = .

Alpha
  = [A-Z]

AlphaNum
  = [A-Z0-9]

ExtraCharacters
  = SourceCharacter+ { return true }

Location
  = AlphaNum AlphaNum?
  { return text(); }

NumericVariableIdentifier
  = Alpha
  / '&theta' { return 'THETA' }

StringVariableIdentifier
  = 'Str' Digit
  { return text(); }

ListVariableIdentifier
  = '&list' Alpha AlphaNum? AlphaNum? AlphaNum? AlphaNum?
  { return 'List' + text().substring(5); }
  / '&L' number:[1-6]
  { return 'List' + number; }

ProgramName
  = Alpha AlphaNum? AlphaNum? AlphaNum? AlphaNum? AlphaNum? AlphaNum? AlphaNum?
  { return text(); }

NumericVariable
  = name:NumericVariableIdentifier { return { type: types.VARIABLE, name } }

StringVariable
  = name:StringVariableIdentifier { return { type: types.STRINGVARIABLE, name } }

ListVariable
  = name:ListVariableIdentifier { return { type: types.LISTVARIABLE, name } }

Variable
  = StringVariable
  / NumericVariable
  / ListVariable

ListIndex
  = list:ListVariable "(" index:ValueExpression OptionalEndParen 
  { return { type: types.LISTINDEX, list, index } }

Assignable
  = ListIndex
  / Variable 

NumericLiteral
  = integer:Integer '.' fraction:Integer? exponent:ExponentPart? { 
    return { type: types.NUMBER, integer, fraction, exponent }
  }
  / '.' fraction:Integer exponent:ExponentPart? { 
    return { type: types.NUMBER, fraction, exponent }
  }
  / integer:Integer exponent:ExponentPart? { 
    return { type: types.NUMBER, integer, exponent }
  }

Digit
  = [0-9]

ExponentPart
  = ExponentIndicator @$(SignedInteger)

ExponentIndicator
  = '&E'

Integer
  = $(Digit+)

SignedInteger
  = $([+-]? Integer)

Character
  = [^"]

CharacterString
  = $(Character*)

StringLiteral
  = '"' chars:CharacterString '"'? 
  { return { type: types.STRING, chars } }

Answer
  = 'Ans'
  { return { type: types.ANS } }

OptionalEndParen
  = ')'?

// Numeric is not included as a "token",
// because they are not distinct and so
// cannot be used in implicit multiplication.
TokenLiteral
  = Answer
  / Assignable
  / StringLiteral

// ----- Expressions -----

ListExpression
 = '{' head:ValueExpression tail:ArgumentExpression* '}'?
 { return util.buildList(head, tail); }

TokenExpression
  = TokenLiteral
  / '(' @ValueExpression ')'
  / ListExpression

UnaryOperator
  = '&-'

TokenUnaryExpression
  = TokenExpression 
  / operator:UnaryOperator argument:TokenUnaryExpression
  { return { type: types.UNARY, operator, argument } }

UnaryExpression
  = TokenUnaryExpression
  / NumericLiteral
  / operator:UnaryOperator argument:UnaryExpression
  { return { type: types.UNARY, operator, argument } }

// See note on TokenLiteral
ImplicitMultiplicativeExpression
  = head:TokenUnaryExpression tail:(UnaryExpression TokenUnaryExpression)* end:UnaryExpression?
  { return util.buildImplicitBinaryExpression(head, tail, end); }
  / head:UnaryExpression tail:(TokenUnaryExpression UnaryExpression)* end:TokenUnaryExpression?
  { return util.buildImplicitBinaryExpression(head, tail, end); }
  / UnaryExpression

MultiplicativeOperator
  = '*'
  / '/'

MultiplicativeExpression
  = head:ImplicitMultiplicativeExpression 
  tail:(MultiplicativeOperator ImplicitMultiplicativeExpression)* 
  { return util.buildBinaryExpression(head, tail); }

AdditiveOperator
  = '+'
  / '-'

AdditiveExpression
  = head:MultiplicativeExpression 
  tail:(AdditiveOperator MultiplicativeExpression)* 
  { return util.buildBinaryExpression(head, tail); }

TestOperator
  = '='
  / '!='
  / '>='
  / '>'
  / '<='
  / '<' 

TestExpression
  = head:AdditiveExpression 
  tail:(TestOperator AdditiveExpression)* 
  { return util.buildBinaryExpression(head, tail); }

ValueExpression
  = TestExpression

ArgumentExpression
  = ',' @ValueExpression

ExtraArguments
  = ArgumentExpression+ { return true }

// ----- Statements -----

ValueStatement
  = value:ValueExpression
  { return { type: types.ValueStatement, value }}

Assignment
  = value:ValueExpression '->' assignable:Assignable 
  { return { type: types.AssignmentStatement, value, assignable }}

// ----- CTL -----
// TODO:
// * DelVar should be able to appear multiple times in a line
// * For( should accept expressions instead of a variable (with interesting behavior)

IfStatement
  = 'If ' value:ValueExpression? extra:ExtraCharacters?
  { return { type: types.IfStatement, value, extra }}

Then 
  = 'Then' extra:ExtraCharacters?
  { return { type: types.ThenStatement, extra }}

Else 
  = 'Else' extra:ExtraCharacters?
  { return { type: types.ElseStatement, extra }}

For
  = 'For(' variable:Variable? start:ArgumentExpression? end:ArgumentExpression? step:ArgumentExpression? args:ExtraArguments? OptionalEndParen extra:ExtraCharacters?
  { return { type: types.ForLoop, variable, start, end, step, args, extra }}

While
  = 'While ' value:ValueExpression? extra:ExtraCharacters?
  { return { type: types.WhileLoop, value, extra }}

Repeat
  = 'Repeat ' value:ValueExpression? extra:ExtraCharacters?
  { return { type: types.RepeatLoop, value, extra }}

End 
  = 'End' extra:ExtraCharacters?
  { return { type: types.EndStatement, extra }}

Pause 
  = 'Pause' 
  { return { type: types.PauseStatement }}

Label
  = 'Lbl ' location:Location
  { return { type: types.LabelStatement, location }}

Goto
  = 'Goto ' location:Location 
  { return { type: types.GotoStatement, location }}

IncrementSkip
  = 'IS>(' variable:Variable? end:ArgumentExpression? OptionalEndParen
  { return { type: types.IncrementSkip, variable, end }}

DecrementSkip
  = 'DS<(' variable:Variable? end:ArgumentExpression? OptionalEndParen
  { return { type: types.DecrementSkip, variable, end }}

Menu
  = 'Menu(' title:ValueExpression? options:(',' StringLiteral ',' Location)* OptionalEndParen
  { return util.buildMenuStatement(title, options); }

Program
  = 'prgm' name:ProgramName
  { return { type: types.ProgramStatement, name }}

Return 
  = 'Return' 
  { return { type: types.ReturnStatement }}

Stop 
  = 'Stop' 
  { return { type: types.StopStatement }}

DelVar 
  = 'DelVar ' variable:Variable?
  { return { type: types.DelVarStatement, variable }}

GraphStyle 
  = 'GraphStyle(' equation:ValueExpression? style:ArgumentExpression? OptionalEndParen
  { return { type: types.GraphStyleStatement, equation, style }}

OpenLib 
  = 'OpenLib(' name:ProgramName OptionalEndParen
  { return { type: types.OpenLibStatement, name }}

ExecLib 
  = 'ExecLib(' name:ProgramName OptionalEndParen
  { return { type: types.ExecLibStatement, name }}

CtlStatement
  = IfStatement
  / Then
  / Else
  / For
  / While
  / Repeat
  / End
  / Pause
  / Label
  / Goto
  / IncrementSkip
  / DecrementSkip
  / Menu
  / Program
  / Return
  / Stop
  / DelVar
  / GraphStyle
  / OpenLib
  / ExecLib

// ----- I/O -----
// TODO:
// * Input

Prompt
  = 'Prompt ' variable:Variable?
  { return { type: types.Prompt, variable } }

Display
  = 'Disp ' value:ValueExpression? 
  { return { type: types.Display, value } }

IoStatement
  // = Input
  = Prompt
  / Display
  // / DispGraph
  // / DispTable
  // / Output(
  // / getKey
  // / ClrHome
  // / ClrTable
  // / GetCalc(
  // / Get(
  // / Send(

// ----- Statement -----
// TODO:
// * More statement types

Statement
  = Assignment
  / CtlStatement
  / IoStatement
  / ValueStatement