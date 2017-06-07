 class ForwardingEntry
   include DefaultLogger

   attr_reader :mac
   attr_reader :port_no
   attr_reader :dpid
   attr_writer :age_max

   def initialize mac, port_no, age_max, dpid
     @mac = mac
     @port_no = port_no
     @age_max = age_max
     @dpid = dpid
     @last_update = Time.now
     debug "New entry: MAC address = #{ @mac.to_s }, port number = #{ @port_no }"
   end

   def update port_no
     debug "Update: The port number of #{ @mac.to_s } has been changed #{ @port_no } => #{ port_no }"
     @port_no = port_no
     @last_update = Time.now
   end

   def aged_out?
     aged_out = Time.now - @last_update > @age_max
     debug "Age out: An entry (MAC address = #{ @mac.to_s }, port number = #{ @port_no }) has been aged-out" if aged_out
     aged_out
   end
 end

 class FDB
   DEFAULT_AGE_MAX = 300

   def initialize
     @db = {}
   end

   def port_no_of mac
     dest = @db[ mac ]
     if dest
       dest.port_no
     else
       nil
     end
   end

   def lookup mac
     if dest = @db[ mac ]
       [ dest.dpid, dest.port_no ]
     else
       nil
     end
   end

   def learn mac, port_no, dpid = nil
     entry = @db[ mac ]
     if entry
       entry.update port_no
     else
       new_entry = ForwardingEntry.new( mac, port_no, DEFAULT_AGE_MAX, dpid )
       @db[ new_entry.mac ] = new_entry
     end
   end

   def age
     @db.delete_if do | mac, entry |
       entry.aged_out?
     end
   end
 end