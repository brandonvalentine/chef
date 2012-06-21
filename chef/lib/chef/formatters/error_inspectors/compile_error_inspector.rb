#--
# Author:: Daniel DeLeo (<dan@opscode.com>)
# Copyright:: Copyright (c) 2012 Opscode, Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

class Chef
  module Formatters
    module ErrorInspectors

      # == CompileErrorInspector
      # Wraps exceptions that occur during the compile phase of a Chef run and
      # tries to find the code responsible for the error.
      class CompileErrorInspector

        attr_reader :path
        attr_reader :exception

        def initialize(path, exception)
          @path, @exception = path, exception
        end

        def add_explanation(error_description)
          error_description.section(exception.class.name, exception.message)

          traceback = filtered_bt.map {|line| "  #{line}"}.join("\n")
          error_description.section("Cookbook Trace:", traceback)
          error_description.section("Relevant File Content:", context)
        end

        def context
          context_lines = []
          context_lines << "#{path}:"
          Range.new(display_lower_bound, display_upper_bound).each do |i|
            line_nr = (i + 1).to_s.rjust(3)
            indicator = (i + 1) == culprit_line ? ">> " : ":  "
            context_lines << "#{line_nr}#{indicator}#{file_lines[i]}"
          end
          context_lines.join("\n")
        end

        def display_lower_bound
          lower = (culprit_line - 8)
          lower = 0 if lower < 0
          lower
        end

        def display_upper_bound
          upper = (culprit_line + 8)
          upper = file_lines.size if upper > file_lines.size
          upper
        end

        def file_lines
          @file_lines ||= IO.readlines(path)
        end

        def culprit_backtrace_entry
          @culprit_backtrace_entry ||= exception.backtrace.find {|line| line =~ /^#{@path}/ }
        end

        def culprit_line
          @culprit_line ||= culprit_backtrace_entry[/^#{@path}:([\d]+)/,1].to_i
        end

        def filtered_bt
          exception.backtrace.select {|l| l =~ /^#{Chef::Config.file_cache_path}/ }
        end

      end

    end
  end
end