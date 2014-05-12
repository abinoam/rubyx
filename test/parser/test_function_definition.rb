require_relative "helper"

class TestFunctionDefinition < MiniTest::Test
  # include the magic (setup and parse -> test method translation), see there
  include ParserHelper
  
  def test_simplest_function
    @string_input    = <<HERE
def foo(x) 
  5
end
HERE
    @parse_output ={:function_name=>{:name=>"foo"}, 
    :parmeter_list=>[{:parmeter=>{:name=>"x"}}], :expressions=>[{:integer=>"5"}], :end=>"end"}
    @transform_output = Ast::FunctionExpression.new('foo', 
                [Ast::NameExpression.new('x')], 
                [Ast::IntegerExpression.new(5)])
    @parser = @parser.function_definition
  end

  def test_function_ops
    @string_input    = <<HERE
def foo(x) 
 abba = 5 
 2 + 5
end
HERE
    @parse_output = {:function_name=>{:name=>"foo"}, 
    :parmeter_list=>[{:parmeter=>{:name=>"x"}}], 
    :expressions=>[{:l=>{:name=>"abba"}, :o=>"= ", :r=>{:integer=>"5"}}, 
      {:l=>{:integer=>"2"}, :o=>"+ ", :r=>{:integer=>"5"}}], :end=>"end"}
    @transform_output = Ast::FunctionExpression.new(:foo, 
      [Ast::NameExpression.new("x")] , 
      [Ast::OperatorExpression.new("=", Ast::NameExpression.new("abba"),Ast::IntegerExpression.new(5)),
        Ast::OperatorExpression.new("+", Ast::IntegerExpression.new(2),Ast::IntegerExpression.new(5))] )
    @parser = @parser.function_definition
  end

  def test_function_if
    @string_input    = <<HERE
def ofthen(n)
  if(0)
    isit = 42
  else
    maybenot = 667
  end
end
HERE
    @parse_output = {:function_name=>{:name=>"ofthen"}, 
    :parmeter_list=>[{:parmeter=>{:name=>"n"}}], 
    :expressions=>[{:if=>"if", :conditional=>{:integer=>"0"}, 
    :if_true=>{:expressions=>[{:l=>{:name=>"isit"}, :o=>"= ", :r=>{:integer=>"42"}}], :else=>"else"}, 
    :if_false=>{:expressions=>[{:l=>{:name=>"maybenot"}, :o=>"= ", :r=>{:integer=>"667"}}], :end=>"end"}}], 
    :end=>"end"}
    @transform_output = Ast::FunctionExpression.new(:ofthen, 
          [Ast::NameExpression.new("n")] , 
          [Ast::ConditionalExpression.new(Ast::IntegerExpression.new(0), 
            [Ast::OperatorExpression.new("=", Ast::NameExpression.new("isit"),
              Ast::IntegerExpression.new(42))],
          [Ast::OperatorExpression.new("=", Ast::NameExpression.new("maybenot"),Ast::IntegerExpression.new(667))] )] )
    @parser = @parser.function_definition
  end

  def test_function_while
    @string_input    = <<HERE
def fibonaccit(n)
  a = 0
  while (n) do
    some = 43
    other = some * 4
  end
end
HERE
    @parse_output ={:function_name=>{:name=>"fibonaccit"}, 
              :parmeter_list=>[{:parmeter=>{:name=>"n"}}], 
              :expressions=>[{:l=>{:name=>"a"}, :o=>"= ", :r=>{:integer=>"0"}}, 
                {:while=>"while", :while_cond=>{:name=>"n"}, :do=>"do", 
                    :body=>{:expressions=>[{:l=>{:name=>"some"}, :o=>"= ", :r=>{:integer=>"43"}},
                           {:l=>{:name=>"other"}, :o=>"= ", :r=>{:l=>{:name=>"some"}, :o=>"* ", :r=>{:integer=>"4"}}}], 
                :end=>"end"}}], 
              :end=>"end"}
    @transform_output = Ast::FunctionExpression.new(:fibonaccit, 
          [Ast::NameExpression.new("n")] , 
          [Ast::OperatorExpression.new("=", Ast::NameExpression.new("a"),Ast::IntegerExpression.new(0)),
            Ast::WhileExpression.new(Ast::NameExpression.new("n"), 
              [Ast::OperatorExpression.new("=", Ast::NameExpression.new("some"),Ast::IntegerExpression.new(43)), 
                Ast::OperatorExpression.new("=", Ast::NameExpression.new("other"),Ast::OperatorExpression.new("*", Ast::NameExpression.new("some"),Ast::IntegerExpression.new(4)))] )] )
    @parser = @parser.function_definition
  end    
end