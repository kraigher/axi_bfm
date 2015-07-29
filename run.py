# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this file,
# You can obtain one at http://mozilla.org/MPL/2.0/.
#
# Copyright (c) 2015, Olof Kraigher olof.kraigher@gmail.com

from os.path import join, dirname
import sys

from vunit import VUnit

root = dirname(__file__)

ui = VUnit.from_argv()
ui.add_osvvm()
lib = ui.add_library("axi_bfm_lib")
lib.add_source_files(join(root, "src", "*.vhd"))
lib.add_source_files(join(root, "src", "test", "*.vhd"))
ui.main()
