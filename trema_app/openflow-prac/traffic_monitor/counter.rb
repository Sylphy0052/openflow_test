require "active_record"

ActiveRecord::Base.establish_connection(
  "adapter" => "sqlite3",
  "database" =>"./traffic.db"
)

class Mac_traffic < ActiveRecord::Base
  self.table_name = 'mac_traffics'
end
class Switch_traffic < ActiveRecord::Base
  self.table_name = 'switch_traffics'
end

 class Counter
   def initialize
     @db = {}
     @swdb = {}
     @sw = []
     @mac = []
   end
   
   def add datapath_id, mac, packet_count, byte_count
     @db[ mac ] ||= { :packet_count => 0, :byte_count => 0 }
     @swdb[ datapath_id ] ||= { :packet_count => 0, :byte_count => 0 }
     @db[ mac ][ :packet_count ] += packet_count
     @db[ mac ][ :byte_count ] += byte_count
     @swdb[ datapath_id ][ :packet_count ]  += packet_count
     @swdb[ datapath_id ][ :byte_count ] += byte_count
     
     
     if Switch_traffic.where(datapath_id: datapath_id.to_i).count==1 then #@sw.include? datapath_id
       #exists
=begin
          update = Switch_traffic.find_by_datapath_id(datapath_id.to_i)
          update.packet = @swdb[ datapath_id ][ :packet_count ]
          update.byte = @swdb[ datapath_id ][ :byte_count ]
          update.save
=end
       result = Switch_traffic.where(:datapath_id => datapath_id.to_i).update_all(
                                                                                  :packet => @swdb[ datapath_id ][ :packet_count ],
                                                                                  :byte => @swdb[ datapath_id ][ :byte_count ]
                                                                                  )
       
       
     else
       #not exists 
       puts datapath_id.to_i
       @sw.push(datapath_id.to_i)
       Switch_traffic.create(
                             :datapath_id => datapath_id.to_i,
                             :packet => packet_count,
                             :byte => byte_count
                             )
     end
     
     if  Mac_traffic.where(mac: mac.to_s).count==1 then#@mac.include? mac then
       #exist  
=begin
          update = Mac_traffic.find_by_mac(mac.to_s)
       update.update_attributes(
                                :packet => @db[ mac ][ :packet_count ],
                                :byte => @db[ mac ][ :byte_count ]
                                )
=end
       result = Mac_traffic.where(:mac => mac.to_s).update_all(
                                                               :packet => @db[ mac ][ :packet_count ],
                                                               :byte => @db[ mac ][ :byte_count ]
                                                               )
     else
       #not exists                                                                 
       @mac.push(mac) 
       Mac_traffic.create({
                            :mac => mac.to_s,
                            :datapath_id => datapath_id,
                            :packet => packet_count,
                            :byte => byte_count
                          })
     end
   end
   
   def dbeach_pair &block
     @db.each_pair &block
   end
   
   def sweach_pair &block
     @swdb.each_pair &block
   end
   
   def counter_reset 
     #     @swdb = {}
     sweach_pair do | dpid, counter |
       @swdb[dpid] = { :packet_count => 0, :byte_count => 0 }
       #       each[:packet_count] = 0
       #       each[:byte_count] = 0 
       result = Switch_traffic.where(:datapath_id => dpid.to_i).update_all(
                                                                           :packet => 0,
                                                                           :byte => 0
                                                                           )
     end 

     dbeach_pair do | mac, counter |
       @db[mac] = { :packet_count => 0, :byte_count => 0 }
       result = Mac_traffic.where(:mac => mac.to_s).update_all(
                                                               :packet => 0,
                                                               :byte => 0
                                                               )
       
     end
   end
   
   
   def show_counter routecounter=false #default false ,if chenge ture when you can check route traffic amount
     puts Time.now
     if routecounter
       dbeach_pair do | mac, counter |
         puts "#{ mac } #{ counter[ :packet_count ] } packets (#{ counter[ :byte_count ] } bytes)"
         progress_bar(:byte_count)
       end
     end
     puts "-------------------------------------------------------------"
     sweach_pair do | dpid, counter |
       puts "Switch Traffic #{ dpid }\t : \t#{ counter[ :packet_count ] } packets (#{ counter[ :byte_count ] } bytes)"
     end
     puts "-------------------------------------------------------------"
     counter_reset
   end
   
   def clear_db
     Switch_traffic.delete_all
     Mac_traffic.delete_all
   end

 end
 
