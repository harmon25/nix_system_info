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
    result_tuple = result.out
      |> String.replace("bytes:","")
      |> String.split()
      |> List.to_tuple()

    data = %{down: String.to_integer(elem(result_tuple, 1)), up: String.to_integer(elem(result_tuple, 5)), total: 0} 
    %{data | :total => data.down + data.up }
  end

  def uptime() do
   result =  Porcelain.shell("uptime")
   result_tpl = result.out |> String.strip() |> String.split(",") |> List.to_tuple()  
   tuple_len = tuple_size(result_tpl)
    cond do
    # up for hours
      tuple_len == 5 ->
        hours = elem(result_tpl, 0) |> String.split() |> List.last()
        %{hours: hours}
     # up for days
      tuple_len == 6 ->
        hours = elem(result_tpl, 1) |> String.strip()

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
    result_tpl = result.out
      |> String.strip()
      |> String.replace("load average:", "")
      |> String.split(",")
      |> List.to_tuple()
    tuple_len = tuple_size(result_tpl)
    [load_1,load_5,load_15] = [String.strip(elem(result_tpl, tuple_len-3)),String.strip(elem(result_tpl, tuple_len-2)), String.strip(elem(result_tpl,tuple_len-1))] 
    %{load_1: load_1 , load_5: load_5 , load_15: load_15 }
  end

  def disks() do
    res = Porcelain.shell("df -T | grep -vE \"tmpfs|rootfs|Filesystem\"")
    disk_stats = res.out 
      |> String.strip()
      |> String.split("\n")
      |> Enum.map(fn x -> 
          String.split(x) |> List.to_tuple()
         end)
  end

  def memory() do 
    result =  Porcelain.exec("free", ["-mo"])
    result_tpl = result.out |> String.strip() |> String.split("\n") |> Enum.map(fn x -> String.split(x) end) |> tl() |> hd() |> List.to_tuple()
    %{free: elem(result_tpl,3), total: elem(result_tpl,1), used: elem(result_tpl,2) }
  end

end
