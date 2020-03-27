module Arm
  # A translator is cpu specific and translates from risc instructions to a given
  # cpu. This one transltes to Arm Instructions.
  class Translator

    # translator should translate from register instructio set to it's own (arm eg)
    # for each instruction we call the translator with translate_XXX
    #  with XXX being the class name.
    # the result is replaced in the stream
    def translate( instruction )
      class_name = instruction.class.name.split("::").last
      self.send( "translate_#{class_name}".to_sym , instruction)
    end

    def translate_Label( code )
      Risc.label( code.source , code.name , code.address)
    end

    # arm indexes are
    #  in bytes, so *4
    # if an instruction is passed in we get the index with index function
    def arm_index( index )
      index = index.index if index.is_a?(Risc::Instruction)
      raise "index error #{index}" if index < 0
      index * 4
    end

    def translate_Transfer( code )
      # Risc machine convention is from => to
      # But arm has the receiver/result as the first
      ArmMachine.mov( code.to , code.from)
    end

    def translate_SlotToReg( code )
      ArmMachine.ldr( *slot_args_for(code) )
    end

    def translate_RegToSlot( code )
      ArmMachine.str( *slot_args_for(code) )
    end

    def slot_args_for( code )
      if(code.index.is_a? Numeric)
        [ code.register ,  code.array  , arm_index(code) ]
      else
        [ code.register ,  code.array  , code.index , :shift_lsl => 2]
      end
    end

    def byte_args_for( code )
      [ code.register ,  code.array  , code.index ]
    end

    def translate_ByteToReg( code )
      ArmMachine.ldrb( *byte_args_for(code) )
    end

    def translate_RegToByte( code )
      ArmMachine.strb( *byte_args_for(code) )
    end

    def translate_FunctionCall( code )
      ArmMachine.b( code.method.binary )
    end

    def translate_FunctionReturn( code )
      reduce = arm_index(Parfait::Integer.integer_index)
      # reduce the int first, register contains a ReturnAddress
      codes = ArmMachine.ldr( code.register , code.register ,  reduce  )
      codes << ArmMachine.mov( :pc , code.register)
      codes
    end

    def translate_DynamicJump(code)
      index = Parfait.object_space.get_type_by_class_name(:CallableMethod).variable_index(:binary)
      codes = ArmMachine.ldr( code.register ,  code.register  , arm_index(index) )
      codes << ArmMachine.mov( :pc , code.register)
      codes
    end

    def translate_LoadConstant( code )
      constant = code.constant
      constant = constant.to_cpu(self) if constant.is_a?(Risc::Label)
      return ArmMachine.add( code.register , constant )
    end

    def translate_LoadData( code )
      return ArmMachine.mov( code.register ,  code.constant )
    end

    def translate_OperatorInstruction( code )
      left = code.left
      right = code.right
      result = code.result
      case code.operator.to_s
      when "+"
        c = ArmMachine.add(result , left , right)
      when "-"
        c = ArmMachine.sub(result , left , right)
      when "&"
        c = ArmMachine.and(result , left , right)
      when "|"
        c = ArmMachine.orr(result , left , right)
      when "*"
        c = ArmMachine.mul(result , right , left) #arm rule about left not being result, lukily commutative
      when ">>"
        c = ArmMachine.mov(result , left , :shift_asr => right) #arm rule about left not being result, lukily commutative
      when "<<"
        c = ArmMachine.mov(result , left , :shift_lsl => right) #arm rule about left not being result, lukily commutative
      else
        raise "unimplemented  '#{code.operator}' #{code}"
      end
      c
    end

    # This implements branch logic, which is simply assembler branch
    #
    # The only target for a call is a Block, so we just need to get the address for the code
    # and branch to it.
    def translate_Branch( code )
      target = code.label.is_a?(Risc::Label) ? code.label.to_cpu(self) : code.label
      ArmMachine.b( target )
    end

    def translate_IsPlus( code )
      ArmMachine.bpl( code.label.to_cpu(self) )
    end

    def translate_IsMinus( code )
      ArmMachine.bmi( code.label.to_cpu(self) )
    end

    def translate_IsZero( code )
      ArmMachine.beq( code.label.to_cpu(self) )
    end

    def translate_IsNotZero( code )
      ArmMachine.bne( code.label.to_cpu(self) )
    end

    def translate_IsOverflow( code )
      ArmMachine.bvs( code.label.to_cpu(self))
    end

    def translate_Syscall( code )
      call_codes = { putstring: 4 , exit: 1 }
      name = code.name
      name = :exit if name == :died
      int_code = call_codes[name]
      raise "Not implemented syscall, #{name}" unless int_code
      send( name , int_code )
    end

    def putstring( int_code )    # adjust for object header (0 based, hence -1)
      codes = ArmMachine.add( :r1 ,  :r1 , (Parfait::Word.type_length - 1)*4 )
      codes.append ArmMachine.mov( :r0 ,  1 )  # write to stdout == 1
      syscall(int_code , codes )
    end

    def exit( int_code )
      codes = ArmMachine.mov( :r7 ,  int_code )
      codes.append ArmMachine.swi( 0 )
      codes
    end

    private

    # syscall is always triggered by swi(0)
    # The actual code (ie the index of the kernel function) is in r7
    def syscall( int_code , codes)
      codes.append ArmMachine.mov( :r7 ,  int_code )
      codes.append ArmMachine.swi( 0 )
      codes
    end

  end
end
