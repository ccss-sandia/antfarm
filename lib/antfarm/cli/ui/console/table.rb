################################################################################
#                                                                              #
# Copyright (2008-2010) Sandia Corporation. Under the terms of Contract        #
# DE-AC04-94AL85000 with Sandia Corporation, the U.S. Government retains       #
# certain rights in this software.                                             #
#                                                                              #
# Permission is hereby granted, free of charge, to any person obtaining a copy #
# of this software and associated documentation files (the "Software"), to     #
# deal in the Software without restriction, including without limitation the   #
# rights to use, copy, modify, merge, publish, distribute, distribute with     #
# modifications, sublicense, and/or sell copies of the Software, and to permit #
# persons to whom the Software is furnished to do so, subject to the following #
# conditions:                                                                  #
#                                                                              #
# The above copyright notice and this permission notice shall be included in   #
# all copies or substantial portions of the Software.                          #
#                                                                              #
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR   #
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,     #
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE  #
# ABOVE COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, #
# WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR #
# IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE          #
# SOFTWARE.                                                                    #
#                                                                              #
# Except as contained in this notice, the name(s) of the above copyright       #
# holders shall not be used in advertising or otherwise to promote the sale,   #
# use or other dealings in this Software without prior written authorization.  #
#                                                                              #
################################################################################

module Antfarm
  module CLI
    module UI
      module Console
        class Table
          attr_writer :header

          def initialize(margin = 5, separator = '=')
            @header    = Array.new
            @rows      = Array.new
            @margin    = margin
            @separator = separator
          end

          def add_header_column(string)
            @header << string
          end

          def add_row(data)
            @rows << data
          end

          def print
            formatter  = build_formatter
            separators = build_separators
            header     = formatter % @header
            separator  = formatter % separators
            term_width = `stty -a | tr -s ';' '\n' | grep "column" | sed s/'[^[:digit:]]'//g`.to_i # yuk!
            puts
            puts header.length > term_width ? header[0,term_width] : header
            puts separator.length > term_width ? separator[0,term_width] : separator
            @rows.each do |row|
              row = formatter % row
              puts row.length > term_width ? row[0,term_width] : row
            end
            puts
          end

          #######
          private
          #######

          def build_formatter
            if @header.empty?
              @header = Array.new(@rows[0].length, '') # yuk again!
            end

            columns = @header.length
            formatter = String.new
            (0...(columns - 1)).each do |column|
              formatter += "%-#{column_width(column)}s "
            end
            formatter += "%s"
            return formatter
          end

          def build_separators
            separators = Array.new
            @header.each_index do |i|
              separators << @separator * (column_width(i) - @margin)
            end
            return separators
          end

          def column_width(column)
            return @widths[column] if @widths
            @widths = Array.new
            @header.each_index do |i|
              max = @header[i].length
              @rows.each do |row|
                length = row[i].nil? ? 0 : row[i].length
                max    = length > max ? length : max
              end
              @widths << max + @margin
            end
            return @widths[column]
          end
        end
      end
    end
  end
end
