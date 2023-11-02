defmodule Servy.GenericServer do
  def start(callback_module, initial_state, name) do
    pid = spawn(__MODULE__, :listen_loop, [initial_state, callback_module])
    Process.register(pid, name)
    pid
  end

  # Helper functions

  def call(pid, message) do
    send(pid, {:call, self(), message})

    receive do
      {:response, response} -> response
    end
  end

  def cast(pid, message) do
    send(pid, {:cast, message})
  end

  # Server
  def listen_loop(state, callback_module) do
    receive do
      {:call, sender, message} when is_pid(sender) ->
        {response, new_state} = callback_module.handle_call(message, state)
        send(sender, {:response, response})
        listen_loop(new_state, callback_module)

      {:cast, message} ->
        new_state = callback_module.handle_cast(message, state)
        listen_loop(new_state, callback_module)

      unexpected ->
        IO.puts("Unexpected message: #{inspect(unexpected)}")
        listen_loop(state, callback_module)
    end
  end
end

defmodule Servy.FourOhFourCounter do
  alias Servy.GenericServer
  @process_name :four_oh_four_counter_process

  def start do
    IO.inspect("Starting the 404 counter process...")
    GenericServer.start(__MODULE__, %{}, @process_name)
  end

  def bump_count(path) do
    GenericServer.call(@process_name, {:bump_count, path})
  end

  def get_count(path) do
    GenericServer.call(@process_name, {:get_count, path})
  end

  def get_counts() do
    GenericServer.call(@process_name, :get_counts)
  end

  # Server
  def listen_loop(state) do
    receive do
      {sender, :bump_count, path} ->
        new_state = Map.update(state, path, 1, &(&1 + 1))
        send(sender, {:response, "Bumped #{path}"})
        listen_loop(new_state)

      {sender, :get_count, path} ->
        count = Map.get(state, path, 0)
        send(sender, {:response, count})
        listen_loop(state)

      {sender, :get_counts} ->
        send(sender, {:response, state})
        listen_loop(state)

      unexpected ->
        IO.puts("Unexpected message: #{inspect(unexpected)}")
        listen_loop(state)
    end
  end

  def handle_call({:bump_count, path}, state) do
    new_state = Map.update(state, path, 1, &(&1 + 1))
    {"Bumped #{path}", new_state}
  end

  def handle_call({:get_count, path}, state) do
    count = Map.get(state, path, 0)
    {count, state}
  end

  def handle_call(:get_counts, state) do
    {state, state}
  end
end
