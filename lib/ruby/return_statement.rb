module Ruby
  class ReturnStatement < Statement
    include Normalizer

    attr_reader :return_value

    def initialize(value)
      @return_value = value || NilConstant.new
    end

    def to_sol
      val , hoisted = *normalized_sol(@return_value)
      me = Sol::ReturnStatement.new(val)
      return me unless hoisted
      Sol::Statements.new( hoisted ) << me
    end

    def to_s(depth = 0)
      at_depth(depth , "return #{@return_value.to_s}")
    end
  end
end
