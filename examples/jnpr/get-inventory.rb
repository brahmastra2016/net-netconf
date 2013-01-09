require 'net/netconf'

puts "NETCONF v.#{Netconf::VERSION}"

login = { :target => '192.168.10.2', 
  :username => "jeremy", 
  :password => "jeremy1" }

Netconf::SSH.new( login ){ |dev|  

  inv = dev.rpc.get_chassis_inventory  

  puts "Chassis: " + inv.xpath('chassis/description').text
  puts "Chassis Serial-Number: " + inv.xpath('chassis/serial-number').text  
    
}



