defmodule Mix.Tasks.Distribution.Push do
  use Mix.Task

  def run([node_name, cookie]) do
    node_name = String.to_atom(node_name)
    {:ok, _} = Node.start(:host)
    Node.set_cookie(String.to_atom(cookie))
    true = Node.connect(node_name)
    config = Mix.Project.config()
    otp_app = config[:app]

    images_path =
      (config[:images_path] || Path.join([Mix.Project.build_path(), "nerves", "images"]))
      |> Path.expand()
    fw_file = Path.join(images_path, "#{otp_app}.fw")

    args = ["-a", "-t", "upgrade", "-d", "/dev/mmcblk0"]
    {:ok, fwup} = :rpc.call(node_name, Fwup, :stream, [self(), args])
    stream = spawn_link(fn() ->
      File.stream!(fw_file, [:bytes], 4096)
      |> Stream.map(fn chunk ->
        :rpc.call(node_name, Fwup, :send_chunk, [fwup, chunk])
      end)
      |> Stream.run()
    end)
    finish(node_name, fwup, stream)
  end

  def finish(node_name, fwup, stream) do
    receive do
      {:fwup, {:progress, prog}} -> IO.write("progress: #{prog}\r")
        finish(node_name, fwup, stream)
      {:fwup, {:ok, 0, ""}} ->
        :rpc.call(node_name, Nerves.Runtime, :reboot, [])
      other ->
        IO.inspect(other, label: "unknown_data")
        finish(node_name, fwup, stream)
    end
  end
end
