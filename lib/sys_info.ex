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
    if OSUtils.is_unix? do
      result =  Porcelain.exec("hostname", ["-f"])
      final_result = result.out |> String.strip()
      {:ok, final_result}
    else
      result =  Porcelain.exec("hostname", [])
      final_result = result.out |> String.strip()
      {:ok, final_result}
    end
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
      {:ok, %{hours: a}}

  """
  def uptime() do
    if OSUtils.is_unix? do
     result =  Porcelain.shell("uptime")
     result_tpl = result.out |> String.strip() |> String.split(",") |> List.to_tuple()  
     tuple_len = tuple_size(result_tpl)
      cond do
        tuple_len == 5 ->
        # up for hours
          hours = elem(result_tpl, 0) |> String.split() |> List.last()
        {:ok , %{hours: hours} }
        tuple_len == 6 ->
        # up for days
          hours = elem(result_tpl, 1) |> String.strip()
          days = elem(result_tpl, 0)
            |> String.replace("days", "")
            |> String.split()
            |> List.last()
            |> String.strip()
          final_result = %{hours: hours, days: days }
          {:ok, final_result}
      end
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

    [load_1,load_5,load_15] = [String.strip(elem(result_tpl, tuple_len-3)), 
                               String.strip(elem(result_tpl, tuple_len-2)), 
                               String.strip(elem(result_tpl,tuple_len-1))] 

    final_result = %{load_1: String.to_float(load_1) * 100, 
                     load_5: String.to_float(load_5)  * 100, 
                     load_15: String.to_float(load_15) * 100
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
            capacity: String.to_integer(String.rstrip(elem(diskInfo,5), "%")), 
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
end
