
require "active_record"


ActiveRecord::Base.establish_connection(
  "adapter" => "sqlite3",
  "database" =>"./routes.db"
)

class Route < ActiveRecord::Base
  self.table_name = 'routes'
end

class IpExtracter < Controller

	def start
          puts "----show all IP----"
          Route.all.each do |accessed|
            puts "ip : #{accessed.ipv4}"
          end
          puts "-------------------"

        end


        def switch_ready datapath_id
          puts "switch ready  #{datapath_id.to_hex}"
        end

  	def packet_in datapath_id, packet_in
          macsa = packet_in.macsa#source_mac_address
          macda = packet_in.macda#destination_mac_address
          ipsa = packet_in.ipv4_saddr#ipv4_source_address
          ipda = packet_in.ipv4_daddr#ipv4_destination_address


          if !ipsa.nil? && "0.0.0.0" != ipsa.to_s then
            puts "----------------------"
            puts "macsa : #{macsa}"
            puts "macda : #{macda}"
            puts "ipsa : #{ipsa.to_s}"
            puts "ipda : #{ipda.to_s}"
            puts "----------------------"

            if Route.where(ipv4: ipsa.to_s).count==0 then
              puts "Not Exists. Add DB"
              Route.create({:ipv4 => ipsa.to_s,
                            :mac => macsa.to_s,
                            :datapath_id => datapath_id,
                            :port => packet_in.in_port.to_s})
            end
          end
    end

end
