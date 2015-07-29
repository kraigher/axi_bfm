-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this file,
-- You can obtain one at http://mozilla.org/MPL/2.0/.
--
-- Copyright (c) 2015, Olof Kraigher olof.kraigher@gmail.com

use std.textio.all;

library vunit_lib;
context vunit_lib.vunit_context;

use work.memory_model_ptype_pkg.all;

entity tb_memory_model is
  generic (
    runner_cfg : runner_cfg_t);
end entity;

architecture tb of tb_memory_model is
begin

  main : process
    variable ptr, ptr2, ptr3 : natural;
    variable memory_model : memory_model_t;
  begin
    test_runner_setup(runner, runner_cfg);
    while test_suite loop
      memory_model.reset(memory_size_in_bytes => 2**10);

      if run("test that memory can be allocated") then
        ptr := memory_model.allocate(num_bytes => 11);
        check_equal(ptr, 0);

      elsif run("test that two allocations does not share base address") then
        ptr := memory_model.allocate(num_bytes => 10);
        ptr2 := memory_model.allocate(num_bytes => 20);
        ptr3 := memory_model.allocate(num_bytes => 3);
        check(ptr /= ptr2);
        check_equal(ptr, 0);
        check_equal(ptr2, 10);
        check_equal(ptr3, 30);

      elsif run("test that allocate with alignment") then
        for alignment in 1 to 5 loop
          ptr := memory_model.allocate(num_bytes => 2**(alignment-1),
                                       alignment => 2**alignment);
          check_equal(ptr mod 2**alignment, 0);
        end loop;

      elsif run("test read and write byte") then
        ptr := memory_model.allocate(num_bytes => 1);
        memory_model.write_byte(ptr, 77);
        check_equal(memory_model.read_byte(ptr), 77);
      end if;

    end loop;
    test_runner_cleanup(runner);
  end process;
end architecture;
-- vunit_pragma fail_on_warning
-- vunit_pragma run_all_in_same_sim
