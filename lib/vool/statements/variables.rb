module Vool
  module Named
    attr_reader :name
    def initialize name
      @name = name
    end
  end

  class LocalVariable < Statement
    include Named
    def to_mom(method)
      if method.args_type.variable_index(@name)
        type = :arguments
      else
        type = :frame
      end
      Mom::SlotDefinition.new(:message , [type , @name])
    end
  end

  class InstanceVariable < Statement
    include Named
    def to_mom(method)
      Mom::SlotDefinition.new(:message , [ :self , @name] )
    end
    # used to collect type information
    def add_ivar( array )
      array << @name
    end
  end

  class ClassVariable < Statement
    include Named
  end

  class ModuleName < Statement
    include Named
  end
end
