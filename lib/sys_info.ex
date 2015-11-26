defmodule SysInfo do
  @moduledoc """
  Provides Pi System Stats
  """
  use Application

  @doc """
  Returns hostname as string
  """
  def hostname() do
    result =  Porcelain.exec("hostname", ["-f"])
    result.out |> String.strip()
  end
  
  @doc """
  Returns number of current tcp connetions as an int
  """
  def connections() do
    result = Porcelain.shell("netstat -nta --inet | wc -l")
    result.out |> String.strip() |> String.to_integer()
  end
 
  @doc """
  Returns number of current tcp connetions as an int
  """
  def net_stats(interface \\ "eth0") do
    result = Porcelain.shell("/sbin/ifconfig #{interface} | grep RX\\ bytes")
    result_tuple = result.out
      |> String.replace("bytes:","")
      |> String.split()
      |> List.to_tuple()

    data = %{down: String.to_integer(elem(result_tuple, 1)), up: String.to_integer(elem(result_tuple, 5)), total: 0} 
    %{data | :total => data.down + data.up }
  end

  @doc """
  Uptime as Map: %{days: x, hours: y} 
  """
  def uptime() do
   result =  Porcelain.shell("uptime")
   result_tpl = result.out |> String.strip() |> String.split(",") |> List.to_tuple()  
   tuple_len = tuple_size(result_tpl)
    cond do
      tuple_len == 5 ->
      # up for hours
        hours = elem(result_tpl, 0) |> String.split() |> List.last()
        %{hours: hours}
     
      tuple_len == 6 ->
      # up for days
        hours = elem(result_tpl, 1) |> String.strip()
        days = elem(result_tpl, 0)
          |> String.replace("days", "")
          |> String.split()
          |> List.last()
          |> String.strip()

        %{hours: hours, days: days } 
    end  
  end

  @doc """
  Returns load averages for last 1, 5 and 15 minutes as floats
  """
  def load() do
    result =  Porcelain.shell("uptime")
    result_tpl = result.out
      |> String.strip()
      |> String.replace("load average:", "")
      |> String.split(",")
      |> List.to_tuple()
    tuple_len = tuple_size(result_tpl)
    [load_1,load_5,load_15] = [String.strip(elem(result_tpl, tuple_len-3)),String.strip(elem(result_tpl, tuple_len-2)), String.strip(elem(result_tpl,tuple_len-1))] 
    %{load_1: String.to_float(load_1) , load_5: String.to_float(load_5) , load_15: String.to_float(load_15) }
  end

  @doc """
  Returns List of mounted file systems
  """
  def disks() do
    res = Porcelain.shell("df -T | grep -vE \"tmpfs|rootfs|Filesystem\"")
    disk_stats = res.out 
      |> String.strip()
      |> String.split("\n")
      |> Enum.map(fn x -> 
          String.split(x) |> List.to_tuple()
         end)
  end

  @doc """
  Returns Map of memory stats as integers
  """
  def memory() do 
    result =  Porcelain.exec("free", ["-mo"])
    result_tpl = result.out |> String.strip() |> String.split("\n") |> Enum.map(fn x -> String.split(x) end) |> tl() |> hd() |> List.to_tuple()
    %{free: String.to_integer(elem(result_tpl,3)), total: String.to_integer(elem(result_tpl,1)), used: String.to_integer(elem(result_tpl,2)) }
  end

end
