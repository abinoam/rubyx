module Vool
  class Assignment < Statement
    attr_reader :name , :value
    def initialize(name , value )
      @name , @value = name , value
    end
    def collect(arr)
      @value.collect(arr)
      super
    end
  end
  class LocalAssignment < Assignment
    # used to collect frame information
    def add_local( array )
      array << @name
    end
  end
  class InstanceAssignment < Assignment
    # used to collect type information
    def add_ivar( array )
      array << @name
    end
  end
end