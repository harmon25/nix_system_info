defmodule PiStats do
 use Application

 def hostname() do
  result =  Porcelain.exec("hostname", ["-f"])
  result.out |> String.strip()
 end

 def connections() do
  result = Porcelain.shell("netstat -nta --inet | wc -l")
  result.out |> String.strip() |> String.to_integer()
 end
 
 def net_stats(int) do
   result = Porcelain.shell("/sbin/ifconfig #{int} | grep RX\\ bytes")
   result_tuple = List.to_tuple(String.split(String.replace(result.out,"bytes:","")))
   data = %{down: String.to_integer(elem(result_tuple, 1)), up: String.to_integer(elem(result_tuple, 5)), total: 0} 
   %{data | :total => data.down + data.up }
 end

 def uptime() do
   result =  Porcelain.shell("uptime")
   split_result = 
     result.out
     |> String.strip()
     |> String.split(",")   
   result_tpl = List.to_tuple(split_result)
   tuple_len = tuple_size(result_tpl)
   cond do
     tuple_len == 5 ->
       IO.puts "up for hours!"
       hours = elem(result_tpl, 0)
             |> String.split()
             |> List.last()
       %{hours: hours}
     tuple_len == 6 ->
        IO.puts "up for days!"
        hours = elem(result_tpl, 1)
              |> String.strip()

        days = elem(result_tpl, 0)
              |> String.replace("days", "")
              |> String.split()
              |> List.last()
              |> String.strip()
     %{hours: hours, days: days } 
   end  
 end

 def load() do
    result =  Porcelain.shell("uptime")
    split_result = 
     result.out
     |> String.strip()
     |> String.replace("load average:", "")
     |> String.split(",")
    result_tpl = List.to_tuple(split_result)
    tuple_len = tuple_size(result_tpl)
    [load_1,load_5,load_15] = [String.strip(elem(result_tpl, tuple_len-3)),String.strip(elem(result_tpl, tuple_len-2)), String.strip(elem(result_tpl,tuple_len-1))] 
    %{load_1: load_1 , load_5: load_5 , load_15: load_15 }
 end

end
