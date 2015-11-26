-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this file,
-- You can obtain one at http://mozilla.org/MPL/2.0/.
--
-- Copyright (c) 2015, Olof Kraigher olof.kraigher@gmail.com

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.memory_model_ptype_pkg.all;

package axi_memory_pkg is

  procedure simulate_read_slave(
    variable memory_model : inout memory_model_t;
    signal aclk : in std_logic;

    signal arvalid : in std_logic;
    signal arready : out std_logic;
    signal arid : in std_logic_vector;
    signal araddr : in std_logic_vector;
    signal arlen : in std_logic_vector;
    signal arsize : in std_logic_vector;
    signal arburst : in std_logic_vector;

    signal rvalid : out std_logic;
    signal rready : in std_logic;
    signal rid : out std_logic_vector;
    signal rdata : out std_logic_vector;
    signal rresp : out std_logic_vector;
    signal rlast : out std_logic);

  procedure simulate_write_slave(
    variable memory_model : inout memory_model_t;
    signal aclk : in std_logic;

    signal awvalid : in std_logic;
    signal awready : out std_logic;
    signal awid : in std_logic_vector;
    signal awaddr : in std_logic_vector;
    signal awlen : in std_logic_vector;
    signal awsize : in std_logic_vector;
    signal awburst : in std_logic_vector;

    signal wvalid : in std_logic;
    signal wready : out std_logic;
    signal wid : in std_logic_vector;
    signal wdata : in std_logic_vector;
    signal wstrb : in std_logic_vector;
    signal wlast : in std_logic;

    signal bvalid : out std_logic;
    signal bready : in std_logic;
    signal bid : out std_logic_vector;
    signal bresp : out std_logic_vector);

end package;

package body axi_memory_pkg is

  type burst_type_t is (fixed, incr, wrap);

  function to_burst_type_t(value : std_logic_vector) return burst_type_t is
  begin
    case value is
      when "00" => return fixed;
      when "01" => return incr;
      when "10" => return wrap;
      when others => report "Invalid burst type" severity error;
    end case;
    return fixed;
  end function;

  procedure simulate_read_slave(
    variable memory_model : inout memory_model_t;
    signal aclk : in std_logic;

    signal arvalid : in std_logic;
    signal arready : out std_logic;
    signal arid : in std_logic_vector;
    signal araddr : in std_logic_vector;
    signal arlen : in std_logic_vector;
    signal arsize : in std_logic_vector;
    signal arburst : in std_logic_vector;

    signal rvalid : out std_logic;
    signal rready : in std_logic;
    signal rid : out std_logic_vector;
    signal rdata : out std_logic_vector;
    signal rresp : out std_logic_vector;
    signal rlast : out std_logic) is

    variable address : integer;
    variable burst_length : integer;
    variable burst_size : integer;
    variable burst_type : burst_type_t;
  begin
    -- Static Error checking
    assert arid'length = rid'length report "arid vs rid data width mismatch";
    assert (arlen'length = 4 or
            arlen'length = 8) report "arlen must be either 4 (AXI3) or 8 (AXI4)";

    -- Initialization
    rvalid <= '0';
    rid <= (rid'range => '0');
    rdata <= (rdata'range => '0');
    rresp <= (rresp'range => '0');
    rlast <= '0';

    loop
      -- Read AR channel
      arready <= '1';
      wait until (arvalid and arready) = '1' and rising_edge(aclk);
      arready <= '0';
      address := to_integer(unsigned(araddr));
      burst_length := to_integer(unsigned(arlen)) + 1;
      burst_size := 2**to_integer(unsigned(arsize));
      burst_type := to_burst_type_t(arburst);
      rid <= arid;
      assert burst_type /= wrap report "Wrapping burst type not supported";

      rdata <= (rdata'range => '0');
      rresp <= "00";                    -- Okay

      for i in 0 to burst_length-1 loop
        for j in 0 to burst_size-1 loop
          rdata(8*j+7 downto 8*j) <= std_logic_vector(to_unsigned(memory_model.read_byte(address+j), 8));
        end loop;

        if burst_type = incr then
          address := address + burst_size;
        end if;

        rvalid <= '1';

        if i = burst_length - 1 then
          rlast <= '1';
        else
          rlast <= '0';
        end if;

        wait until (rvalid and rready) = '1' and rising_edge(aclk);
        rvalid <= '0';
      end loop;

    end loop;
  end;

  procedure simulate_write_slave(
    variable memory_model : inout memory_model_t;
    signal aclk : in std_logic;

    signal awvalid : in std_logic;
    signal awready : out std_logic;
    signal awid : in std_logic_vector;
    signal awaddr : in std_logic_vector;
    signal awlen : in std_logic_vector;
    signal awsize : in std_logic_vector;
    signal awburst : in std_logic_vector;

    signal wvalid : in std_logic;
    signal wready : out std_logic;
    signal wid : in std_logic_vector;
    signal wdata : in std_logic_vector;
    signal wstrb : in std_logic_vector;
    signal wlast : in std_logic;

    signal bvalid : out std_logic;
    signal bready : in std_logic;
    signal bid : out std_logic_vector;
    signal bresp : out std_logic_vector) is

    variable address : integer;
    variable burst_length : integer;
    variable burst_size : integer;
    variable burst_type : burst_type_t;

  begin
    -- Static Error checking
    assert awid'length = bid'length report "arwid vs wid data width mismatch";
    assert (awlen'length = 4 or
            awlen'length = 8) report "awlen must be either 4 (AXI3) or 8 (AXI4)";

    -- Initialization
    wready <= '0';
    bvalid <= '0';
    bid <= (bid'range => '0');
    bresp <= (bresp'range => '0');

    loop
      awready <= '1';
      wait until (awvalid and awready) = '1' and rising_edge(aclk);
      awready <= '0';
      address := to_integer(unsigned(awaddr));
      burst_length := to_integer(unsigned(awlen)) + 1;
      burst_size := 2**to_integer(unsigned(awsize));
      burst_type := to_burst_type_t(awburst);
      assert burst_type /= wrap report "Wrapping burst type not supported";

      bid <= awid;
      bresp <= "00";                    -- Okay

      for i in 0 to burst_length-1 loop
        wready <= '1';
        wait until (wvalid and wready) = '1' and rising_edge(aclk);
        wready <= '0';

        for j in 0 to burst_size-1 loop
          if wstrb(j) = '1' then
            memory_model.write_byte(address+j, to_integer(unsigned(wdata(8*j+7 downto 8*j))));
          end if;
        end loop;

        if burst_type = incr then
          address := address + burst_size;
        end if;

        assert (wlast = '1') = (i = burst_length-1) report "invalid wlast";
      end loop;

      bvalid <= '1';
      wait until (bvalid and bready) = '1' and rising_edge(aclk);
      bvalid <= '0';
    end loop;
  end;
end package body;
