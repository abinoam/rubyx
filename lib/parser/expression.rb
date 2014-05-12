module Parser
  module Expression
    include Parslet
    
    rule(:simple_expression) { function_call | integer | string | name }

    rule(:expression) { (while_do | conditional | operator_expression | function_call ) >> newline }

    def delimited_expressions( delimit )
      ( (delimit.absent? >> expression).repeat(1)).as(:expressions) >> delimit
    end

    rule(:expressions_do)     { delimited_expressions(keyword_do) }
    rule(:expressions_else)   { delimited_expressions(keyword_else) }
    rule(:expressions_end)    { delimited_expressions(keyword_end) }

  end
end
