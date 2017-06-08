class Clone < Controller

    @pm1_mac = "b8:27:eb:47:8e:ed"
    @pm2_mac = "b8:27:eb:22:e2:9f"
    @pm1_ip = "192.10.1.10"
    @pm2_ip = "192.20.1.10"
    @pm1_port = 3
    @pm2_port = 4
    @port = 1


    def start
        puts "trema clone start."
        # puts "clone from #{ARGV[0]} to #{ARGV[1]}"
        @fromip = ARGV[0]
        @toip = ARGV[1]
        @flag = 0
        @ipcache = []
    end

    def switch_ready datapath_id
        puts "switch connect #{datapath_id.to_hex}"

        send_flow_mod_add(
            datapath_id,
            :match => Match.new( :dl_type => 0x0806 ),
            :actions => SendOutPort.new( OFPP_FLOOD )
        )

        # 192.10.1.10から来たパケットを1番ポートに転送
        send_flow_mod_add(
            datapath_id,
            :match => Match.new(
                :dl_type => 0x0800 ,
                :nw_src => @pm1_ip ),
            :actions => SendOutPort.new( @port )
                          )
        # 192.20.1.10から来たパケットの転送元を書き換えて1番ポートに転送
        action1 =
        [
            SetEthSrcAddr.new( @pm1_mac ),
            SetIpSrcAddr.new( @pm1_ip ),
            SendOutPort.new( 1 )
        ]
        send_flow_mod_add(
            datapath_id,
            :match => Match.new(
                :dl_type => 0x0800 ,
                :nw_dst => @pm2_ip ),
            :actions => action1
        )
    end

    # 宛先が192.10.1.10なら負荷分散処理
    def packet_in datapath_id, message
        srcip = message.ipv4_saddr.to_s
        dstip = message.ipv4_daddr.to_s
        if dstip == @pm1_ip && !(@ipcache.index( srcip ))
            @ipcache << srcip
            puts ""
            puts "Arrive packets From #{srcip} to #{dstip}"
            loadbalance datapath_id, message
        end
    end

    # フローエントリー削除
    def flow_removed datapath_id, message
        delip = message.match.nw_src.to_s
        puts ""
        puts "delete #{delip}"
        @ipcache -= [delip]
    end

###########################
    private
###########################

    def loadbalance datapath_id, message
        if @flag == 0
            send_flow_mod_add(
                datapath_id,
                :match => Match.new(
                    :dl_type => 0x0800,
                    :nw_src => message.ipv4_saddr
                ),
                :actions => SendOutPort.new( @pm1_port ),
                :idle_timeout => 300
            )

            send_packet_out(
                datapath_id,
                :data => message.data,
                :actions => SendOutPort.new( @pm1_port )
            )
            puts "Send to Server1 Registration to flow table"
            @flag = 1

        else
            action2 = [
                SetEthDstAddr.new(@pm2_mac),
                SetIpDstAddr.new(@pm2_ip),
                SendOutPort.new(@pm2_port)
            ]
            send_flow_mod_add(
                datapath_id,
                :match => Match.new(
                    :dl_type => 0x0800,
                    :nw_src => message.ipv4_saddr
                ),
                :actions => action2,
                :idle_timeout => 300
            )
            send_packet_out(
                datapath_id,
                :data => message.data,
                :actions => action2
            )
            puts "Send to Server2 Registration to flow table"
            @flag = 0
        end
    end
end
