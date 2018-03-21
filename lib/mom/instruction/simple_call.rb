module Mom

  # A SimpleCall is just that, a simple call. This could be called a function call too,
  # meaning we managed to resolve the function at compile time and all we have to do is
  # actually call it.
  #
  # As the call setup is done beforehand (for both simple and cached call), the
  # calling really means mostly jumping to the address. Simple.
  #
  class SimpleCall < Instruction
    attr_reader :method

    def initialize(method)
      @method = method
    end

    # To call the method, we determine the jumpable address (method.binary), move that
    # into a register and issue a FunctionCall
    #
    # For returning, we add a label after the call, and load it's address into the
    # return_address of the next_message, for the ReturnSequence to pick it up.
    def to_risc(compiler)
      reg = compiler.use_reg(:int)
      return_label = Risc::Label.new(self,"continue")
      load =  SlotLoad.new([:message,:next_message,:return_address],[return_label])
      moves = load.to_risc(compiler)
      moves << Risc::FunctionCall.new(self, method ,reg)
      moves << return_label
    end

  end

end
