module Mom

  # The ReturnSequence models the return from a method.
  #
  # This involves the jump to the return address stored in the message, and
  # the reinstantiation of the previous message.
  #
  # The machine (mom) only ever "knows" one message, the current message.
  # Messages are a double linked list, calling involves going forward,
  # returning means going back.
  #
  # The return value of the current message is transferred into the return value of the
  # callers return value during the swap of messages, and just before the jump.
  #
  # The callers perspective of a call is the magical apperance of a return_value
  # in it's message at the instruction after the call.
  #
  # The instruction is not parameterized as it translates to a constant
  # set of lower level instructions.
  #
  class ReturnSequence < Instruction
    def to_risc(compiler)
      return_move = SlotLoad.new( [:message , :caller,:return_value] , [:message , :return_value],self)
      moves = return_move.to_risc(compiler)
      compiler.reset_regs
      return_address = compiler.use_reg(:ReturnAddress)
      message = Risc.message_reg
      moves << Risc.slot_to_reg(self,message, :return_address , return_address)
      moves << Risc.slot_to_reg(self,return_address , Parfait::Integer.integer_index , return_address)
      moves << Risc.slot_to_reg(self,message , :caller , message)
      moves << Risc::FunctionReturn.new(self, return_address)
    end

    def to_s
      "ReturnSequence"
    end
  end

end
