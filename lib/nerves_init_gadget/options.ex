defmodule Nerves.InitGadget.Options do
  @moduledoc false

  alias Nerves.InitGadget.Options

  host_cookie_path = Path.join(System.user_home(), ".erlang.cookie")

  host_cookie =
    case File.read(host_cookie_path) do
      {:ok, cookie} -> cookie
      _ -> nil
    end

  defstruct ifname: "usb0",
            address_method: :dhcpd,
            mdns_domain: "nerves.local",
            node_name: nil,
            node_host: :mdns_domain,
            ssh_console_port: 22,
            host_cookie: host_cookie,
            cookie: nil

  def get() do
    :nerves_init_gadget
    |> Application.get_all_env()
    |> Enum.into(%{})
    |> merge_defaults()
  end

  defp merge_defaults(settings) do
    Map.merge(%Options{}, settings)
  end
end
