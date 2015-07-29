-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this file,
-- You can obtain one at http://mozilla.org/MPL/2.0/.
--
-- Copyright (c) 2015, Olof Kraigher olof.kraigher@gmail.com

package memory_model_ptype_pkg is
  subtype byte_t is integer range 0 to 2**8-1;

  type byte_vector_t is array (integer range <>) of byte_t;
  type byte_vector_ptr_t is access byte_vector_t;

  type memory_model_t is protected
    procedure reset(memory_size_in_bytes : natural);
    impure function allocate(num_bytes : natural; alignment : positive := 1) return natural;
    procedure write_byte(address : natural; value : byte_t);
    impure function read_byte(address : natural) return byte_t;
  end protected;
end package;

package body memory_model_ptype_pkg is
  type memory_model_t is protected body
    variable size : natural := 0;
    variable base_address : natural := 0;
    variable bytes : byte_vector_ptr_t := null;

    procedure reset(memory_size_in_bytes : natural) is
    begin
      size := memory_size_in_bytes;
      base_address := 0;
      if bytes /= null then
        deallocate(bytes);
      end if;
      bytes := new byte_vector_t(0 to size-1);
    end procedure;

    impure function allocate(num_bytes : natural; alignment : positive := 1) return natural is
      variable ptr : natural;
    begin
      base_address := base_address + ((-base_address) mod alignment);
      ptr := base_address;
      base_address := base_address + num_bytes;
      return ptr;
    end function;

    procedure write_byte(address : natural; value : byte_t) is
    begin
      bytes(address) := value;
    end procedure;

    impure function read_byte(address : natural) return byte_t is
    begin
      return bytes(address);
    end function;

  end protected body;
end package body;
