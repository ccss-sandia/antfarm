################################################################################
#                                                                              #
# Copyright (2008-2014) Sandia Corporation. Under the terms of Contract        #
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

require File.expand_path(File.dirname(__FILE__) + '/lib/antfarm/version')

Gem::Specification.new do |s|
  s.name          = %q{antfarm}
  s.version       = "#{Antfarm.version}"
  s.authors       = ['Bryan T. Richardson']
  s.email         = %q{btricha@sandia.gov}
  s.date          = Time.now.strftime('%Y-%m-%d')
  s.summary       = %q{Passive network mapping tool}
  s.description   = %q{ANTFARM is a passive network mapping tool capable of
                       parsing data files generated by common network
                       administration tools, network equipment configuration
                       files, etc. Designed for use when assessing critical
                       infrastructure control systems.}
  s.homepage      = %q{https://github.com/ccss-sandia/antfarm}
  s.files         = Dir['{bin,lib,man}/**/*','README.md'].to_a
  s.require_paths = ['lib']
  s.executables  << 'antfarm'
  s.has_rdoc      = false

  s.add_dependency 'activerecord',   '= 3.2.12'
  s.add_dependency 'ipaddress',      '= 0.8.0'
  s.add_dependency 'launchy',        '= 2.1.2'
  s.add_dependency 'packetfu',       '= 1.1.6'
  s.add_dependency 'pg',             '= 0.14.1'
  s.add_dependency 'pry',            '= 0.9.12'
  s.add_dependency 'slim',           '= 2.0.2'
  s.add_dependency 'sqlite3',        '= 1.3.7'
  s.add_dependency 'terminal-table', '= 1.4.5'
  s.add_dependency 'trollop',        '= 2.0'
end
