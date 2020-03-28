module Risc
  # To create a binary, we need a so called Text element. Bad name for what is the code
  #
  # Binary code is already created by the Machine (by translating risc to arm to binary)
  #
  # This class serves to write all the objects of the linker (wich also contain the code)
  # into one stream or binary text object. This is then written to an ELF text section.
  #
  # A word about positions: The c world has a thing called position independent code, and
  # basically we follw that idea. Code (ie jumps and constant loads) are all relative.
  # But we have pointers. In C the linker takes care of bending those, we have to
  # do that ourselves, in write_ref. That's why we need the load adddess and basically
  # we just add it to pointers.

  class TextWriter
    include Util::Logging
    log_level :info

    def initialize(linker)
      @linker = linker
      raise "may not me nil" if linker.nil?
    end

    # objects must be written in same order as positioned by the linker, namely
    # - intial jump
    # - all objects
    # - all BinaryCode
    def write_as_string
      @stream = StringIO.new
      write_init(@linker.cpu_init)
      write_debug
      write_objects
      write_code
      log.debug "Assembled 0x#{stream_position.to_s(16)} bytes"
      return @stream.string
    end

    def sorted_objects
      @linker.object_positions.keys.sort do |left , right|
        Position.get(left).at <=> Position.get(right).at
      end
    end
    # debugging loop to write out positions (in debug)
    def write_debug
      sorted_objects.each do |objekt|
        next if objekt.is_a?(Risc::Label)
        log.debug "Linked #{objekt.class}:0x#{objekt.object_id.to_s(16)} at #{Position.get(objekt)} / 0x#{objekt.padded_length.to_s(16)}"
      end
    end

    # Write all the objects in the order that they have been positioed
    def write_objects
      sorted_objects.each do |objekt|
        next unless Position.is_object(objekt)
        write_any( objekt )
      end
    end

    # Write the BinaryCode objects of all methods to stream.
    # Really like any other object, it's just about the ordering
    def write_code
      @linker.assemblers.each do |asm|
        asm.callable.each_binary do |code|
          write_any(code)
        end
      end
    end

    # Write any object just logs a bit and passes to write_any_out
    def write_any( obj )
      write_any_log( obj ,  "Write")
      if stream_position != Position.get(obj).at
        raise "Write #{obj.class}:0x#{obj.object_id.to_s(16)} at 0x#{stream_position.to_s(16)} not #{Position.get(obj)}"
      end
      write_any_out(obj)
      write_any_log( obj ,  "Wrote")
      Position.get(obj)
    end

    def write_any_log( obj , at)
      log.debug "#{at} #{obj.class}:0x#{obj.object_id.to_s(16)} at stream 0x#{stream_position.to_s(16)} pos:#{Position.get(obj)} , len:0x#{obj.padded_length.to_s(16)}"
    end

    # Most objects are the same and get passed to write_object
    # But Strings and BinaryCode write out binary, so they have different methods (for now)
    def write_any_out(obj)
      case obj
      when Parfait::Word, Symbol
        write_String obj
      when Parfait::BinaryCode
        write_BinaryCode( obj )
      when Parfait::ReturnAddress
        write_return_address( obj )
      when Parfait::Integer
        write_integer( obj )
      when Parfait::Data4
        write_data4( obj )
      else
        write_object( obj )
      end
    end

    # write type of the instance, and the variables that are passed
    # variables ar values, ie int or refs. For refs the object needs to save the object first
    def write_object( object )
      obj_written = write_object_variables(object)
      log.debug "instances=#{object.get_instance_variables.inspect} mem_len=0x#{object.padded_length.to_s(16)}"
      indexed_written = write_object_indexed(object)
      log.debug "type #{obj_written} , total #{obj_written + indexed_written} (array #{indexed_written})"
      log.debug "Len = 0x#{object.get_length.to_s(16)} , inst =0x#{object.get_type.instance_length.to_s(16)}" if object.is_a? Parfait::Type
      pad_after( obj_written + indexed_written  )
      Position.get(object)
    end

    def write_object_indexed(object)
      written = 0
      if( object.is_a? Parfait::List)
        object.each do |inst|
          write_ref_for(inst)
          written += 4
        end
      end
      written
    end

    def write_object_variables(object)
      written = 0 # compensate for the "secret" marker
      object.get_instance_variables.each do |var|
        inst = object.get_instance_variable(var)
        #puts "Nil for #{object.class}.#{var}" unless inst
        inst = nil if [:cpu_instructions , :risc_instructions].include?(var)
        write_ref_for(inst)
        written += 4
      end
      written
    end

    def write_return_address( addr )
      write_ref_for( addr.get_type )
      write_ref_for( addr.next_integer )
      val = addr.value ? addr.value + @linker.platform.loaded_at : Parfait.object_space.nil_object
      write_ref_for( val )
      write_ref_for( 0 )
      log.debug "Integer witten stream 0x#{@stream.length.to_s(16)}"
    end

    def write_integer( int )
      write_ref_for( int.get_type )
      write_ref_for( int.next_integer )
      write_ref_for( int.value )
      write_ref_for( 0 )
      log.debug "Integer witten stream 0x#{@stream.length.to_s(16)}"
    end

    def write_data4( code )
      write_ref_for( code.get_type )
      write_ref_for( code.get_type )
      case code
      when Parfait::NilClass , nil
        fake_int = 0
      when Parfait::TrueClass , true
        fake_int = 1
      when Parfait::FalseClass , false
        fake_int = 0
      else
        fake_int = code.get_type
      end
      write_ref_for( fake_int )
      write_ref_for( code.get_type )
      log.debug "Data4 witten stream 0x#{@stream.length.to_s(16)}"
    end

    # first jump,
    def write_init( cpu_init )
      cpu_init.assemble(@stream)
      @stream.write_unsigned_int_8(0) until @linker.platform.padding == stream_position
      log.debug "Init witten stream 0x#{@stream.length.to_s(16)}"
    end

    def write_BinaryCode( code )
      write_ref_for( code.get_type )
      write_ref_for( code.next_code )
      code.each_word do |word|
        @stream.write_unsigned_int_32( word || 0 )
      end
      log.debug "Code16 witten stream 0x#{@stream.length.to_s(16)}"
    end

    def write_String( string )
      if string.is_a? Parfait::Word
        str = string.to_string
        raise "length mismatch #{str.length} != #{string.char_length}" if str.length != string.char_length
      end
      str = string.to_s if string.is_a? Symbol
      log.debug "#{string.class} is #{string} at 0x#{Position.get(string)} length 0x#{string.length.to_s(16)}"
      write_checked_string(string , str)
    end

    def write_checked_string(string, str)
      write_ref_for( string.get_type ) #ref
      @stream.write_signed_int_32( str.length  ) #int
      @stream.write str
      pad_after(str.length + 8 ) # type , length
      log.debug "String (0x#{string.length.to_s(16)}) stream 0x#{@stream.length.to_s(16)}"
    end

    def write_Symbol(sym)
      return write_String(sym)
    end

    private

    # write means we write the resulting address straight into the assembler stream
    # object means the object of which we write the address
    def write_ref_for( object )
      if(object.is_a?( ::Integer) )
        return @stream.write_signed_int_32(object)
      end
      case object
      when nil
        object = Parfait.object_space.nil_object
      when true
        object = Parfait.object_space.true_object
      when false
        object = Parfait.object_space.nil_object
      end
      @stream.write_signed_int_32(Position.get(object) + @linker.platform.loaded_at)
    end

    # pad_after is always in bytes and pads (writes 0's) up to the next 8 word boundary
    def pad_after( length )
      before = stream_position
      pad =  Parfait::Object.padded(length) - length  # for header, type
      pad.times do
        @stream.write_unsigned_int_8(0)
      end
      after = stream_position
      log.debug "padded 0x#{length.to_s(16)} with 0x#{pad.to_s(16)} stream #{before.to_s(16)}/#{after.to_s(16)}"
    end

    # return the stream length as hex
    def stream_position
      @stream.length
    end
  end

end
