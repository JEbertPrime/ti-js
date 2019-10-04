// TI-Basic Grammar
// ==================

{
    const types = require ('./types.js');
    const util = require ('./pegutil.js');
}

Start
    = Statement

// ----- Components -----
// TODO:
// * Lists

Location
  = [A-Z0-9][A-Z0-9]?
  { return text(); }

VariableIdentifier
  = [A-Z]
  / "&theta" { return "THETA" }

Variable
  = name:VariableIdentifier { return { type: types.VARIABLE, name } }

NumericLiteral
  = integer:Integer "." fraction:Integer? exponent:ExponentPart? { 
    return { type: types.NUMBER, integer, fraction, exponent }
  }
  / "." fraction:Integer exponent:ExponentPart? { 
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
  = "&E"

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
  = "Ans"
  { return { type: types.ANS } }

OptionalEndParen
  = ")"?

Literal
  = NumericLiteral
  / Answer
  / Variable
  / StringLiteral

// ----- Expressions -----

PrimaryExpression
  = Literal
  / "(" @ValueExpression ")"

UnaryOperator
  = "-"

UnaryExpression
  = PrimaryExpression 
  / operator:UnaryOperator argument:UnaryExpression
  { return { type: types.UNARY, operator, argument } }

MultiplicativeOperator
  = "*"
  / "/"

MultiplicativeExpression
  = head:UnaryExpression 
  tail:(MultiplicativeOperator UnaryExpression)* 
  { return util.buildBinaryExpression(head, tail); }

AdditiveOperator
  = "+"
  / "-"

AdditiveExpression
  = head:MultiplicativeExpression 
  tail:(AdditiveOperator MultiplicativeExpression)* 
  { return util.buildBinaryExpression(head, tail); }

TestOperator
  = "="
  / "!="
  / ">="
  / ">"
  / "<="
  / "<" 

TestExpression
  = head:AdditiveExpression 
  tail:(TestOperator AdditiveExpression)* 
  { return util.buildBinaryExpression(head, tail); }

ValueExpression
  = TestExpression

// ----- Statements -----

ValueStatement
  = value:ValueExpression
  { return { type: types.ValueStatement, value }}

Assignment
  = value:ValueExpression "->" variable:Variable 
  { return { type: types.AssignmentStatement, value, variable }}

// ----- CTL -----
// TODO:
// * Everything after Menu
// * Arguments should always be optional (and result in argument error)

IfStatement
  = "If " value:ValueExpression 
  { return { type: types.IfStatement, value }}

Then 
  = "Then" 
  { return { type: types.ThenStatement }}

Else 
  = "Else" 
  { return { type: types.ElseStatement }}

For
  = "For(" variable:Variable "," start:ValueExpression "," end:ValueExpression "," step:ValueExpression OptionalEndParen 
  { return { type: types.ForLoop, variable, start, end, step }}

While
  = "While " value:ValueExpression
  { return { type: types.WhileLoop, value }}

Repeat
  = "Repeat " value:ValueExpression
  { return { type: types.RepeatLoop, value }}

End 
  = "End" 
  { return { type: types.EndStatement }}

Pause 
  = "Pause" 
  { return { type: types.PauseStatement }}

Label
  = "Lbl " location:Location
  { return { type: types.LabelStatement, location }}

Goto
  = "Goto " location:Location 
  { return { type: types.GotoStatement, location }}

IncrementSkip
  = "IS>(" variable:Variable "," end:ValueExpression OptionalEndParen
  { return { type: types.IncrementSkip, variable, end }}

DecrementSkip
  = "DS<(" variable:Variable "," end:ValueExpression OptionalEndParen
  { return { type: types.DecrementSkip, variable, end }}

// Menu("Title","Option 1",Label 1[,…,"Option 7",Label 7])
Menu
  = "Menu(" 
  { return { type: types.MenuStatement }}

Program
  = "prgm" 
  { return { type: types.ProgramStatement }}

Return 
  = "Return" 
  { return { type: types.ReturnStatement }}

Stop 
  = "Stop" 
  { return { type: types.StopStatement }}

DelVar 
  = "DelVar" 
  { return { type: types.DelVarStatement }}

GraphStyle 
  = "GraphStyle(" 
  { return { type: types.GraphStyleStatement }}

OpenLib 
  = "OpenLib(" 
  { return { type: types.OpenLibStatement }}

ExecLib 
  = "ExecLib(" 
  { return { type: types.ExecLibStatement }}

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
  = "Prompt " variable:Variable
  { return { type: types.Prompt, variable } }

Display
  = "Disp " value:ValueExpression 
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