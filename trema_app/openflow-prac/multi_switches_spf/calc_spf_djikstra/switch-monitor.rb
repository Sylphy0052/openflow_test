# -*- coding: utf-8 -*-
#
# Monitor switch on/off
#
# Author: Yasuhito Takamiya <yasuhito@gmail.com>
#
# Copyright (C) 2008-2012 NEC Corporation
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License, version 2, as
# published by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
#




INFINITY_LINK_COST = 999999999
SELF = -1
require "lldp"


class SwitchMonitor < Controller
  #periodic_timer_event :show_switches, 3
  periodic_timer_event :topology_probe, 5
  periodic_timer_event :path, 20
  
  def start
    @topology = Topology.new
    @lldp = Lldp.new
  end

  # handler for switch boots
  def switch_ready datapath_id
    @topology.add_sw datapath_id
    #@lldp.probe datapath_id
  end

  # handler for switch die
  def switch_disconnected datapath_id
    @topology.del_sw datapath_id
  end
  
  def packet_in datapath_id, message
    if @lldp.lldp? message
      @topology.update message
    end

    
    
  end
  
  ###########################################################################
  private
  ###########################################################################
  
  def show_switches
    @topology.show_switches
  end

  def topology_probe
    @topology.switches.each do | dpid |
      @lldp.probe dpid
    end
    

  end

  def path
    p @topology.path(0xe0, 0xe7)
  end
end


### Local variables:
### mode: Ruby
### coding: utf-8
### indent-tabs-mode: nil
### End:
