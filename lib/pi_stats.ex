defmodule PiStats do
 use Application

 def get_hostname() do
  result =  Porcelain.exec("hostname", ["-f"])
  IO.inspect String.strip(result.out)
 end

 def get_connections() do
  result = Porcelain.shell("netstat -nta --inet | wc -l")
  IO.inspect String.strip(result.out)
 end
 
 def net_stats(int) do
   result = Porcelain.shell("/sbin/ifconfig #{int} | grep RX\\ bytes")
   result_tuple = List.to_tuple(String.split(String.replace(result.out,"bytes:","")))
   data = %{:down => String.to_integer(elem(result_tuple, 1)), :up => String.to_integer(elem(result_tuple, 5)), :total => 0} 
   %{data | :total => data.down + data.up }
 end

 def uptime() do
   result =  Porcelain.shell("uptime")
   split_result = 
     result.out
     |> String.strip()
     |> String.replace("load average:", "")
     |> String.split(",")   
   result_tpl =   List.to_tuple(split_result)
   cond do
     tuple_size(result_tpl) == 4 ->
       "up for hours"
     tuple_size(result_tpl) == 5 ->
       "up for days"
   end  
end

end
