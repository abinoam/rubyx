module Register

  # RegisterReference is not the name for a register, "only" for a certain use of it.
  # In a way it is like a variable name, a storage location. The location is a register off course,
  # but which register can be changed, and _all_ instructions sharing the RegisterReference then
  # use that register
  # In other words a simple level of indirection, or change from value to reference sematics.

  class RegisterReference

    attr_accessor :symbol

    def initialize r
      raise "wrong type for register init #{r}" unless r.is_a? Symbol
      raise "double r #{r}" if r.to_s[0,1] == "rr"
      raise "not reg #{r}" unless self.class.look_like_reg r
      @symbol = r
    end

    def self.convert something
      return something unless something.is_a? Symbol
      return something unless look_like_reg(something)
      return new(something)
    end

    def self.look_like_reg is_it
      if( [:lr , :pc].include? is_it )
        return true
      end
      if( (is_it.to_s.length < 3) and (is_it.to_s[0] == "r"))
        return true
      end
      return false
    end

    def == other
      return false if other.nil?
      return false if other.class != RegisterReference
      symbol == other.symbol
    end

    #helper method to calculate with register symbols
    def next_reg_use by = 1
      int = @symbol[1,3].to_i
      sym = "r#{int + by}".to_sym
      RegisterReference.new( sym )
    end

    SELF_REG = :r0
    MESSAGE_REG = :r1
    FRAME_REG = :r2
    NEW_MESSAGE_REG = :r3

    TMP_REG = :r4

    def self.self_reg
      new SELF_REG
    end
    def self.message_reg
      new MESSAGE_REG
    end
    def self.frame_reg
      new FRAME_REG
    end
    def self.new_message_reg
      new NEW_MESSAGE_REG
    end
    def self.tmp_reg
      new TMP_REG
    end

    def sof_reference_name
      @symbol
    end

  end

end
