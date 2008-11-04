# This source file requires all of the necessary gems and source files for ActiveWarehouse. If you
# load this source file all of the other required files and gems will also be brought into the 
# runtime.

#--
# Copyright (c) 2006-2007 Anthony Eden
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#++

$:.unshift(File.dirname(__FILE__)) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

require 'rubygems'
require 'active_support'
require 'active_record'

$:.unshift(File.dirname(__FILE__) + "/../../actionpack/lib")
require 'action_pack'
require 'action_controller'
require 'action_view'

require 'fastercsv'
require 'fileutils'
require 'adapter_extensions'

require 'active_warehouse/ordered_hash'
require 'active_warehouse/field'
require 'active_warehouse/aggregate_field'
require 'active_warehouse/calculated_field'
require 'active_warehouse/version'
require 'active_warehouse/core_ext'
require 'active_warehouse/prejoin_fact'
require 'active_warehouse/fact'
require 'active_warehouse/bridge'
require 'active_warehouse/dimension'
require 'active_warehouse/cube'
require 'active_warehouse/cube_query_result'
require 'active_warehouse/aggregate'
require 'active_warehouse/report'
require 'active_warehouse/view'
require 'active_warehouse/builder'
require 'active_warehouse/migrations'