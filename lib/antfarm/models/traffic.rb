# Copyright (2008) Sandia Corporation.
# Under the terms of Contract DE-AC04-94AL85000 with Sandia Corporation,
# the U.S. Government retains certain rights in this software.
#
# Original Author: Bryan T. Richardson, Sandia National Laboratories <btricha@sandia.gov>
#
# This library is free software; you can redistribute it and/or modify it
# under the terms of the GNU Lesser General Public License as published by
# the Free Software Foundation; either version 2.1 of the License, or (at
# your option) any later version.
#
# This library is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License for more
# details.
#
# You should have received a copy of the GNU Lesser General Public License
# along with this library; if not, write to the Free Software Foundation, Inc.,
# 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA 

# Traffic class that wraps the traffic table
# in the ANTFARM database.
#
# * belongs to a layer 3 interface (defined as source_layer3_interface)
# * belongs to a layer 3 interface (defined as target_layer3_interface)
class Traffic < ActiveRecord::Base
  set_table_name "traffic"

  belongs_to :source_layer3_interface, :class_name => "Layer3Interface", :foreign_key => "source_layer3_interface_id"
  belongs_to :target_layer3_interface, :class_name => "Layer3Interface", :foreign_key => "target_layer3_interface_id"
end

