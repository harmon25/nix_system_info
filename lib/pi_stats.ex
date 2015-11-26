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
   result_tpl = List.to_tuple(split_result)
   tuple_len = tuple_size(result_tpl)
   cond do
     tuple_len == 5 ->
       "up for hours"
       hours = elem(result_tpl, 0)
             |> String.split()
             |> List.last()
       [load_1,load_5,load_15] = [elem(result_tpl, tuple_len-3),elem(result_tpl, tuple_len-2), elem(result_tpl,tuple_len-1) ] 
       %{uptime: %{hours: hours}, load:%{l1: load_1 , l5: load_5 , l15: load_15 } }
     tuple_len == 6 ->
       "up for days"
       result_tpl
   end  
end

end
