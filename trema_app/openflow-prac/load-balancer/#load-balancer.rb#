class LoadBalancer < Controller

#Switch On
  def switch_ready( switchid )
    puts ""
    puts "---Catch Switch---"
    puts "  Init FlowEntry  "

    @flag = 0
    @ipcache = []

    #ARP -----Flooding
    send_flow_mod_add(
      switchid,
      match:Match.new( dl_type: 0x0806 ),
      actions: SendOutPort.new( OFPP_FLOOD )
    )

    #From IP addres is no1 ....... to port 1
    send_flow_mod_add(
      switchid,
      match: Match.new( dl_type: 0x0800,
                           nw_src: "192.168.1.1" ),
      actions: SendOutPort.new( 1 ),
      priority: 0xfff2
    )

    #From IP addres is no2 ........ change From ip ,and send port 1

    action1 =
    [
      SetEthSrcAddr.new( "00:0d:5e:ee:32:d2" ),
      SetIpSrcAddr.new( "192.168.1.1" ),
      SendOutPort.new( 1 )
    ]

    send_flow_mod_add(
      switchid,
      match: Match.new( dl_type: 0x0800,
                           nw_src: "192.168.1.2"),
      actions: action1,
      priority: 0xfff2
    )

  end

  #CatchPacket
  def packet_in( switchid, message )
    #Send IP address  ...... load-barancing
    srcip = message.ipv4_saddr.to_s
    dstip = message.ipv4_saddr.to_s

    if dstip == "192.168.1.1" && !( @ipcache.index(srcip) )
      @ipcache << srcip
      puts ""
      puts "Unknown IP (#{srcip}) send packet to server"

      loadbalance switchid,message
    end
  end

  #FlowEntry Delete
  def flow_removed( switchid, message )
    delip = message.match.nw_src.to_s
    puts""
    puts"#{delip} entry is deleted"
    @ipcache -= [delip]
  end

  ###################
    private
  ###################

  #load-barancing system
  def loadbalance( switchid, message )

    #flag = 0 -> send server 1
    if @flag == 0
      send_flow_mod_add(
        switchid,
        match: Match.new( dl_type: 0x0800,
                             nw_src: message.ipv4_saddr ),
        actions: SendOutPort.new( 2 ),
        priority: 0xfff1,
        idle_timeout: 300
      )
      send_packet_out(
        switchid,
        data: message.data,
        actions: SendOutPort.new( 2 )
      )
      puts"Send server1 . added FlowTable"
      @flag = 1

    #flag==1 is send to server 2
    else
      action2 =
      [
        SetEthDstAddr.new( "00:23:26:5f:8b:29" ),
        SetIpDstAddr.new( "192.168.1.2" ),
        SendOutPort.new( 3 )
      ]
      send_flow_mod_add(
        switchid,
        match: Match.new( dl_type: 0x0800,
                             nw_src: message.ipv4_saddr),
        actions: action2,
        priority: 0xfff1,
        idle_timeout: 300
      )
      send_packet_out(
        switchid,
        data: message.data,
        actions: action2
      )
      puts" send server2, added FlowTable "
      @flag =0
    end
  end
end