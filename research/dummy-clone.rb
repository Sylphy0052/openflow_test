# -*- coding: utf-8 -*-
class Clone < Controller

    def start
        puts "trema clone start."
        @from_ip = "192.10.1.10"
        @to_ip = "192.20.1.10"
        @flag = 0
        @ipcache = []
        @mod_ip = []
        # @vm_mac = "02:fd:01:de:ad:34"
        puts "clone from #{@from_ip} to #{@to_ip}"
        @from_mac = "b8:27:eb:47:8e:ed"
        @to_mac = "b8:27:eb:22:e2:9f"
        # @pm1_ip = "192.10.1.10"
        # @pm2_ip = "192.20.1.10"
        # @pm1_port = 3
        # @pm2_port = 4
        # @port = 1
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
                :nw_src => @from_ip ),
            :actions => SendOutPort.new( OFPP_FLOOD )
        )
        # 192.20.1.10から来たパケットの転送元を書き換えて1番ポートに転送
        action1 =
        [
            SetEthSrcAddr.new( @from_mac ),
            SetIpSrcAddr.new( @from_ip ),
            SendOutPort.new( OFPP_FLOOD )
        ]
        send_flow_mod_add(
            datapath_id,
            :match => Match.new(
                :dl_type => 0x0800 ,
                :nw_dst => @to_ip ),
            :actions => action1
        )
    end

    # 宛先が192.10.1.10なら負荷分散処理
    def packet_in datapath_id, packet_in

        macsa = packet_in.macsa#source_mac_address
        macda = packet_in.macda#destination_mac_address
        ipsa = packet_in.ipv4_saddr#ipv4_source_address
        ipda = packet_in.ipv4_daddr#ipv4_destination_address


        if !ipsa.nil? && "0.0.0.0" != ipsa.to_s && (ipsa.to_s == "192.10.1.10")  then
          puts "----------------------"
          puts "macsa : #{macsa}"
          puts "macda : #{macda}"
          puts "ipsa : #{ipsa.to_s}"
          puts "ipda : #{ipda.to_s}"
          puts "----------------------"

        end

        srcip = packet_in.ipv4_saddr.to_s
        dstip = packet_in.ipv4_daddr.to_s
        if dstip == @from_ip && !(@ipcache.index( srcip ))
            @ipcache << srcip
            puts ""
            puts "Arrive packets From #{srcip} to #{dstip}"
            loadbalance datapath_id, packet_in
        end

        if @mod_ip.index(dstip)
            puts ""
            puts "return ModIp"
            action3 = [
                SetEthSrcAddr.new(@from_mac),
                SetIpSrcAddr.new(@from_ip),
                SendOutPort.new(OFPP_FLOOD)
            ]
            send_flow_mod_add(
                datapath_id,
                :match => Match.new(
                    :dl_type => 0x0800,
                    :nw_src => srcip
                ),
                :actions => action3
            )
            send_packet_out(
                datapath_id,
                :data => packet_in.data,
                :actions => SendOutPort.new(OFPP_FLOOD)
            )
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
                :actions => SendOutPort.new( OFPP_FLOOD )
            )

            send_packet_out(
                datapath_id,
                :data => message.data,
                :actions => SendOutPort.new( OFPP_FLOOD )
            )
            puts "Send to Server1 Registration to flow table"
            @flag = 1

        else
            action2 = [
                SetEthDstAddr.new(@to_mac),
                SetIpDstAddr.new(@to_ip),
                SendOutPort.new(OFPP_FLOOD)
            ]
            send_flow_mod_add(
                datapath_id,
                :match => Match.new(
                    :dl_type => 0x0800,
                    :nw_src => message.ipv4_saddr
                ),
                :actions => action2
            )
            send_packet_out(
                datapath_id,
                :data => message.data,
                :actions => SendOutPort.new(OFPP_FLOOD)
            )
            puts "Send to Server2 Registration to flow table"
            @flag = 0
            @mod_ip << message.ipv4_saddr
        end
    end
end
