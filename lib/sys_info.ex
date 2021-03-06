defmodule SysInfo do
  @moduledoc """
  Provides Pi System Stats
  """
  use Application
  @genericError "Hmm sorry, not *nix"

  @doc """
  Returns hostname as string

  ## Examples:
    
      iex> SysInfo.hostname
      {:ok, "hostname"}
  
  """
  def hostname() do
    :inet.gethostname()
  end
  
  @doc """
  Returns number of current tcp connetions as an int

  ## Examples:

      iex> SysInfo.connections
      {:ok, INT}

  """
  def connections() do
    if OSUtils.is_unix? do
      result = Porcelain.shell("netstat -nta --inet | wc -l")
      final_result = result.out |> String.strip() |> String.to_integer()
      {:ok, final_result}
    else
       {:err, %{msg: @genericError }}
    end
  end

  @doc """
  Returns number of current tcp connetions as an int

  ## Examples:

      iex> SysInfo.net_stats "wlan0"
      {:ok, %{down: INT, up: INT, total: INT}}
  
  """
  def net_stats(interface \\ "eth0") when is_binary(interface) do
    if OSUtils.is_unix? do
      result = Porcelain.shell("/sbin/ifconfig #{interface} | grep RX\\ bytes")
      result_tuple = result.out
        |> String.replace("bytes:","")
        |> String.split()
        |> List.to_tuple()

      data = %{down: String.to_integer(elem(result_tuple, 1)), 
               up: String.to_integer(elem(result_tuple, 5)), 
               total: 0} 

      {:ok, %{data | :total => data.down + data.up } }
    else
        {:err, %{msg: @genericError}}
    end
  end

  @doc """
  Uptime as Map

  ## Examples:

      iex> SysInfo.uptime
      {:ok, %{s: seconds, m: minutes, d: days, h:hours, y: years}}

  """
  def uptime() do
    if OSUtils.is_unix? do
     result =  Porcelain.shell("cat /proc/uptime")
     uptime = result.out 
        |> String.split()
        |> hd()
        |> Integer.parse()
        |> elem(0)
        |> convertUptime()
      {:ok,  uptime}  
    else
       {:err, %{msg: @genericError}}
    end  
  end

  @doc """
  Returns load averages for last 1, 5 and 15 minutes as floats

  ## Examples:

      iex> SysInfo.load
      {:ok, %{load_1: a, load_5: b, load_15: c} }

  """
  def load() do
   if OSUtils.is_unix? do
    result =  Porcelain.shell("uptime")
    result_tpl = result.out
      |> String.strip()
      |> String.replace("load average:", "")
      |> String.split(",")
      |> List.to_tuple()
      
    tuple_len = tuple_size(result_tpl)

    final_result = %{load_1: String.strip(elem(result_tpl, tuple_len-3)), 
                     load_5: String.strip(elem(result_tpl, tuple_len-2)),  
                     load_15: String.strip(elem(result_tpl,tuple_len-1))
                    }
    {:ok, final_result }
   else
       {:err, %{msg: @genericError}}
   end
  end

  @doc """
  Returns List of mounted file systems

  ## Examples:

      iex> SysInfo.disks
      {:ok, []}

  """
  def disks() do
   if OSUtils.is_unix? do
    res = Porcelain.shell("df -T | grep -vE \"tmpfs|rootfs|Filesystem\"")
    disk_stats = res.out 
      |> String.strip()
      |> String.split("\n")
      |> Enum.map(fn x -> 
          String.split(x) |> List.to_tuple()
         end)
      |> Enum.map(fn diskInfo ->
          %{device: elem(diskInfo,0),
            type: elem(diskInfo,1), 
            size: String.to_integer(elem(diskInfo,2)), 
            capacity: elem(diskInfo,5), 
            mountpoint: elem(diskInfo,6)
           }
         end)
      {:ok, disk_stats }
    else
       {:err, %{msg: @genericError}}
    end
  end

  @doc """
  Returns Map of memory stats as integers
  
  ## Examples:

      iex> SysInfo.memory
      {:ok, %{free: a, total: b, used: c}}

  """
  def memory() do 
    if OSUtils.is_unix? do
      result =  Porcelain.exec("free", ["-mo"])
      result_tpl = result.out |> String.strip() |> String.split("\n") |> Enum.map(fn x -> String.split(x) end) |> tl() |> hd() |> List.to_tuple()
      final_result = %{free: String.to_integer(elem(result_tpl,3)), 
                       total: String.to_integer(elem(result_tpl,1)),
                       used: String.to_integer(elem(result_tpl,2))
                      }
      {:ok, final_result }
    else
      {:err, %{msg: @genericError}}
    end
  end

  defp convertUptime(seconds) do
    %{
      y: round((seconds / 60 / 60 / 24 / 365)), 
      d: (seconds / 60 / 60 / 24) |> round() |> rem(365), 
      h: (seconds / 3600) |> round() |> rem(24), 
      m: (seconds / 60) |> round() |> rem(60), 
      s: seconds |> rem(60)
     }
  end

end
