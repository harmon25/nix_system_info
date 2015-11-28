defmodule SysInfo do
  @moduledoc """
  Provides Pi System Stats
  """
  use Application
  @genericError "Hmm sorry, not *nix"

  def hostname() do
   :inet.gethostname()
  end
  
  defp connections() do
   get() do
      result = Porcelain.shell("netstat -nta --inet | wc -l")
      final_result = result.out |> String.strip() |> String.to_integer()
      {:ok, final_result}
    end
  end

  defp net_stats(interface \\ "eth0") when is_binary(interface) do
    get() do
      result = Porcelain.shell("/sbin/ifconfig #{interface} | grep RX\\ bytes")
      result_tuple = result.out
        |> String.replace("bytes:","")
        |> String.split()
        |> List.to_tuple()

      data = %{down: String.to_integer(elem(result_tuple, 1)), 
               up: String.to_integer(elem(result_tuple, 5)), 
               total: 0} 

      {:ok, %{data | :total => data.down + data.up } }
    end
  end

  defp uptime() do
    get() do
     result =  Porcelain.shell("cat /proc/uptime")
     uptime = result.out 
        |> String.split()
        |> hd()
        |> Integer.parse()
        |> elem(0)
        |> convertUptime()
      {:ok,  uptime}  
    end  
  end

  defp load() do
   get() do
    result =  Porcelain.shell("uptime")
    result_tpl = result.out
      |> String.strip()
      |> String.replace("load average:", "")
      |> String.split(",")
      |> List.to_tuple()
      
    tuple_len = tuple_size(result_tpl)

    {:ok, 
    %{load_1: String.strip(elem(result_tpl, tuple_len-3)), 
      load_5: String.strip(elem(result_tpl, tuple_len-2)),  
      load_15: String.strip(elem(result_tpl,tuple_len-1))
      }     
    }
   end
  end

  defp disks() do
    get() do
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
    end
  end

  defp memory() do 
     get() do
        result =  Porcelain.exec("free", ["-mo"])
        result_tpl = result.out |> String.strip() |> String.split("\n") |> Enum.map(fn x -> String.split(x) end) |> tl() |> hd() |> List.to_tuple()
        {:ok, %{free: String.to_integer(elem(result_tpl,3)), 
          total: String.to_integer(elem(result_tpl,1)),
          used: String.to_integer(elem(result_tpl,2))
         } }
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


  @doc """
    Return system info, accepts an atom as tje first argument
    Followed by optional arguments
    :memory
    :uptime
    :load
    :disks
    :net_stats, "eth0"
    :connections
  
  ## Examples:

      iex> SysInfo.memory
      {:ok, %{free: a, total: b, used: c}}

  """

  def get(block) do
     if OSUtils.is_unix? do
       block.()
     else
        {:err, %{msg: @genericError}}
     end
  end

  def get(block, opt) do
     if OSUtils.is_unix? do
       block.(opt)
     else
        {:err, %{msg: @genericError}}
     end
  end

end
