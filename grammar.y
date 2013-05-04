class Parser

#Tokens from lexer
token IF ELSE
token WHILE
token UNLESS
token DEF
token CLASS
token NEWLINE
token NUMBER
token STRING
token TRUE FALSE NIL
token IDENTIFIER
token CONSTANT
token ATTRIBUTE
token INDENT DEDENT


prechigh
  left  '.'
  right '!'
  left  '*' '/'
  left  '+' '-'
  left  '>' '>=' '<' '<='
  left  '==' '!='
  left  '['
  right ']'
  left  '&&'
  left  '||'
  right '='
  left  ','
  left '<<'
  right UNLESS
preclow

rule

  
  
 
  Root:
    /* nothing */                      { result = Nodes.new([]) }
  | Expressions                        { result = val[0] }
  ;
  
 
  Expressions:
    Expression                         { result = Nodes.new(val) }
  | Expressions Terminator Expression  { result = val[0] << val[2] }
    # To ignore trailing line breaks
  | Expressions Terminator             { result = val[0] }
  | Terminator                         { result = Nodes.new([]) }
  ;


  Expression:
    Literal
  | Call
  | Operator
  | Constant
  | Attribute
  | Assign
  | Def
  | Class
  | If
  | While
  | Unless
  | Lambda
  | '(' Expression ')'    { result = val[1] }
  ;
  

  Terminator:
    NEWLINE
  | ";"
  ;
  

  Literal:
    NUMBER                        { result = NumberNode.new(val[0]) }
  | STRING                        { result = StringNode.new(val[0]) }
  | TRUE                          { result = BoolNode.new(true)}
  | FALSE                         { result = BoolNode.new(false) }
  | NIL                           { result = BoolNode.new(nil) }
  ;
  
  
  Call:
    # method call w/o args, or local var access
    IDENTIFIER                    { result = CallNode.new(nil, val[0], []) }
    # method(args)
  | IDENTIFIER "(" ArgList ")"    { result = CallNode.new(nil, val[0], val[2]) }
    # receiver.method 
  | Expression "." IDENTIFIER     { result = CallNode.new(val[0], val[2], []) }
    # receiver.method(args)
  | Expression "." IDENTIFIER "(" ArgList ")"  { result = CallNode.new(val[0], val[2], val[4]) }
   # receiver[prop_name]
  | Expression  "[" ArgList "]" { result = CallNode.new(val[0], "get_slot", val[2]) }
   # receiver[prop_name] = Expression
  | Expression "[" ArgList "]" "=" Expression {result = CallNode.new(val[0], "set_slot", val[2]<<val[5])}
  ;
  
  Lambda:
     "^" ParamList "(" Expressions ")" {  result = LambdaNode.new(val[1],val[3])  }


  
  ArgList:
    /* nothing */                 { result = [] }
  | Expression                    { result = val }
  | ArgList "," Expression        { result = val[0] << val[2] }
  ;
  
  Operator:
  # Binary operators
    Expression '||' Expression    { result = CallNode.new(val[0], val[1], [val[2]]) }
  | Expression '&&' Expression    { result = CallNode.new(val[0], val[1], [val[2]]) }
  | Expression '==' Expression    { result = CallNode.new(val[0], val[1], [val[2]]) }
  | Expression '!=' Expression    { result = CallNode.new(val[0], val[1], [val[2]]) }
  | Expression '>' Expression     { result = CallNode.new(val[0], val[1], [val[2]]) }
  | Expression '>=' Expression    { result = CallNode.new(val[0], val[1], [val[2]]) }
  | Expression '<' Expression     { result = CallNode.new(val[0], val[1], [val[2]]) }
  | Expression '<=' Expression    { result = CallNode.new(val[0], val[1], [val[2]]) }
  | Expression '+' Expression     { result = CallNode.new(val[0], val[1], [val[2]]) }
  | Expression '-' Expression     { result = CallNode.new(val[0], val[1], [val[2]]) }
  | Expression '*' Expression     { result = CallNode.new(val[0], val[1], [val[2]]) }
  | Expression '/' Expression     { result = CallNode.new(val[0], val[1], [val[2]]) }
  | '!' Expression     { result = CallNode.new(val[1], val[0],[]) } 
  ;
  
  Constant:
    CONSTANT                      { result = GetConstantNode.new(val[0]) }
  ;
  
  Attribute:
    ATTRIBUTE                      { result = GetAttrNode.new(val[0]) }
  ;
  
  
  Assign:
    IDENTIFIER "=" Expression     { result = SetLocalNode.new(val[0], val[2]) }
  | CONSTANT "=" Expression       { result = SetConstantNode.new(val[0], val[2]) }
  | ATTRIBUTE "=" Expression       { result = SetAttrNode.new(val[0], val[2]) }
  ;
  
  
  Def:
    DEF IDENTIFIER Block          { result = DefNode.new(val[1], [], val[2]) }
  | DEF IDENTIFIER
      "(" ParamList ")" Block     { result = DefNode.new(val[1], val[3], val[5]) }
  ;

  ParamList:
    /* nothing */                 { result = [] }
  | IDENTIFIER                    { result = val }
  | ParamList "," IDENTIFIER      { result = val[0] << val[2] }
  ;
  
 
  Class:
    CLASS CONSTANT Block          { result = ClassNode.new(val[1], val[2],nil) }
  | CLASS CONSTANT  "<<"  CONSTANT Block  { result = ClassNode.new(val[1], val[4],val[3]) }
  ;
  
 
  If:
   IF Expression Block ELSE Block { result = IfNode.new(val[1], val[2],val[4]) }
  |IF Expression Block   { result = IfNode.new(val[1], val[2],nil) }
  ;
  
  While:
    WHILE Expression Block           { result = WhileNode.new(val[1], val[2]) }
  ;
  
  Unless:
   Expression UNLESS Expression    { result = UnlessNode.new(val[2], val[0]) }
  ;
  
  #Indentation based block could be replaced with "{" and "}"
  Block:
    INDENT Expressions DEDENT     { result = val[1] }
   ;
end

---- header
  require "lexer"
  require "nodes"

---- inner
  
  def parse(code, show_tokens=false)
    @tokens = Lexer.new.tokenize(code) 
    puts @tokens.inspect if show_tokens
    do_parse 
  end
  
  def next_token
    @tokens.shift
  end