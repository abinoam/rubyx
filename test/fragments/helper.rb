require_relative '../helper'

#test the generation of code fragments. 
# ie parse                assumes @string_input
#   compile
#   assemble/write        assume a @should array with the bytes in it

module Fragments
  # need a code generator, for arm 
  def setup
    @program = Vm::Program.new "Arm"
  end

  def parse 
    parser = Parser::Crystal.new
    syntax  = parser.parse_with_debug(@string_input)
    parts   = Parser::Transform.new.apply(syntax)
    # file is a list of expressions, all but the last must be a function
    # and the last is wrapped as a main
    parts.each_with_index do |part,index|
      if index == (parts.length - 1)
        expr    = part.compile( @program.context , @program.main )
      else
        expr    = part.compile( @program.context ,  nil )
        raise "should be function definition for now" unless expr.is_a? Vm::Function
      end
    end
  end

  # helper to write the file
  def write name
    writer = Elf::ObjectWriter.new(@program , Elf::Constants::TARGET_ARM)
    assembly = writer.text
    # use this for getting the bytes to compare to :  
    #puts assembly
    writer.save("#{name}_test.o")
    assembly.text.bytes.each_with_index do |byte , index|
      is = @should[index]
      assert_equal  Fixnum , is.class , "@#{index.to_s(16)} = #{is}"
      assert_equal  byte , is  , "@#{index.to_s(16)} #{byte.to_s(16)} != #{is.to_s(16)}"
    end
  end
end
