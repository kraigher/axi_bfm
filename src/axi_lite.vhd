-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this file,
-- You can obtain one at http://mozilla.org/MPL/2.0/.
--
-- Copyright (c) 2015, Olof Kraigher olof.kraigher@gmail.com

library ieee;
use ieee.std_logic_1164.all;

package axi_lite_pkg is
  procedure axi_lite_read(
    constant address : in std_logic_vector;
    variable result : inout std_logic_vector;

    signal aclk : in std_logic;

    signal arready : in std_logic;
    signal arvalid : out std_logic;
    signal araddr : out std_logic_vector;

    signal rready : out std_logic;
    signal rvalid : in std_logic;
    signal rdata : in std_logic_vector;
    signal rresp : in std_logic_vector);

  procedure axi_lite_write(
    constant address : in std_logic_vector;
    constant data : in std_logic_vector;
    constant stb : in std_logic_vector;

    signal aclk : in std_logic;

    signal awready : in std_logic;
    signal awvalid : out std_logic;
    signal awaddr : out std_logic_vector;

    signal wready : in std_logic;
    signal wvalid : out std_logic;
    signal wdata : out std_logic_vector;
    signal wstb : out std_logic_vector;

    signal bvalid : in std_logic;
    signal bready : out std_logic;
    signal bresp : in std_logic_vector);

end package;

package body axi_lite_pkg is
  procedure axi_lite_read(
    constant address : in std_logic_vector;
    variable result : inout std_logic_vector;

    signal aclk : in std_logic;

    signal arready : in std_logic;
    signal arvalid : out std_logic;
    signal araddr : out std_logic_vector;

    signal rready : out std_logic;
    signal rvalid : in std_logic;
    signal rdata : in std_logic_vector;
    signal rresp : in std_logic_vector) is
  begin
    araddr <= address;
    arvalid <= '1';
    wait until (arvalid and arready) = '1' and rising_edge(aclk);
    arvalid <= '0';

    rready <= '1';
    wait until (rvalid and rready) = '1' and rising_edge(aclk);
    rready <= '0';
    result := rdata;
    assert rresp = "00" report "Got non-OKAY rresp";
  end;

  procedure axi_lite_write(
    constant address : in std_logic_vector;
    constant data : in std_logic_vector;
    constant stb : in std_logic_vector;

    signal aclk : in std_logic;

    signal awready : in std_logic;
    signal awvalid : out std_logic;
    signal awaddr : out std_logic_vector;

    signal wready : in std_logic;
    signal wvalid : out std_logic;
    signal wdata : out std_logic_vector;
    signal wstb : out std_logic_vector;

    signal bvalid : in std_logic;
    signal bready : out std_logic;
    signal bresp : in std_logic_vector) is

    variable w_done, aw_done : boolean := false;
  begin
    awaddr <= address;
    wdata <= data;
    wstb <= (wstb'range => '1');

    wvalid <= '1';
    awvalid <= '1';

    while not (w_done and aw_done) loop
      wait until ((awvalid and awready) = '1' or (wvalid and wready) = '1') and rising_edge(aclk);

      if (awvalid and awready) = '1' then
        awvalid <= '0';
        aw_done := true;
      end if;

      if (wvalid and wready) = '1' then
        wvalid <= '0';
        w_done := true;
      end if;
    end loop;

    bready <= '1';
    wait until (bvalid and bready) = '1' and rising_edge(aclk);
    bready <= '0';
    assert bresp = "00" report "Got non-OKAY bresp";
  end;

end package body;
