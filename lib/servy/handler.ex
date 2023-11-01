require Logger

defmodule Servy.Handler do
  @moduledoc "Handles HTTP requests."
  alias Servy.Conv
  alias Servy.BearController

  @pages_path Path.expand("../../pages", __DIR__)

  import Servy.Plugins, only: [rewrite_path: 1, log: 1, track: 1]
  import Servy.Parser, only: [parse: 1]
  import Servy.FileHandler, only: [handle_file: 2]

  @doc "Transform the request into a response."
  def handle(request) do
    request
    |> parse
    |> log
    |> rewrite_path
    # |> log
    |> route
    |> track
    |> put_content_length
    |> format_response
  end

  def route(%Conv{method: "GET", path: "/sensors"} = conv) do
    task = Task.async(fn -> Servy.Tracker.get_location("bigfoot") end)

    snapshots =
      ["cam-1", "cam-2", "cam-3"]
      |> Enum.map(&Task.async(fn -> Servy.VideoCam.get_snapshot(&1) end))
      |> Enum.map(&Task.await/1)

    where_is_bigfoot = Task.await(task)

    %{conv | status: 200, resp_body: inspect({snapshots, where_is_bigfoot})}
  end

  def route(%Conv{method: "GET", path: "/kaboom"} = _conv) do
    raise "Kaboom!"
  end

  def route(%Conv{method: "GET", path: "/hibernate/" <> time} = conv) do
    time |> String.to_integer() |> :timer.sleep()

    %{conv | status: 200, resp_body: "Awake!"}
  end

  def route(%Conv{method: "GET", path: "/faq"} = conv) do
    html =
      @pages_path
      |> Path.join("faq.md")
      |> File.read()
      |> elem(1)
      |> IO.inspect()
      |> Earmark.as_html!()

    %{conv | status: 200, resp_body: html}
  end

  def route(%Conv{method: "GET", path: "/wildthings"} = conv) do
    %{conv | status: 200, resp_body: "Bears, Lions, Tigers"}
  end

  def route(%Conv{method: "GET", path: "/bears"} = conv) do
    BearController.index(conv)
  end

  def route(%Conv{method: "GET", path: "/api/bears"} = conv) do
    Servy.Api.BearController.index(conv)
  end

  def route(%Conv{method: "POST", path: "/api/bears"} = conv) do
    Servy.Api.BearController.create(conv, conv.params)
  end

  def route(%Conv{method: "GET", path: "/pages/" <> page_name} = conv) do
    @pages_path
    |> Path.join("#{page_name}.html")
    |> File.read()
    |> handle_file(conv)
  end

  def route(%Conv{method: "GET", path: "/bears/new"} = conv) do
    file =
      @pages_path
      |> Path.join("form.html")

    case File.read(file) do
      {:ok, content} ->
        %{conv | status: 200, resp_body: content}

      {:error, :enoent} ->
        Logger.error("Not Found")
        %{conv | status: 404, resp_body: "File not found"}

      {:error, reason} ->
        Logger.error("#{reason}")
        %{conv | status: 500, resp_body: "File error: #{reason}"}
    end
  end

  def route(%Conv{method: "GET", path: "/bears/" <> id} = conv) do
    params = Map.put(conv.params, "id", id)
    BearController.show(conv, params)
  end

  # name=Baloo&type=Brown
  def route(%Conv{method: "POST", path: "/bears"} = conv) do
    BearController.create(conv, conv.params)
  end

  def route(%Conv{method: "DELETE", path: "/bears/" <> _id} = conv) do
    BearController.delete(conv, conv.params)
  end

  def route(%Conv{method: "GET", path: "/about"} = conv) do
    @pages_path
    |> Path.join("about.html")
    |> File.read()
    |> handle_file(conv)
  end

  def route(%Conv{path: path} = conv) do
    %{conv | status: 404, resp_body: "No #{path} here!"}
  end

  # def route(%{method: "GET", path: "/about"} = conv) do
  #   file =
  #     @pages_path
  #     |> Path.join("about.html")

  #   case File.read(file) do
  #     {:ok, content} ->
  #       %{conv | status: 200, resp_body: content}

  #     {:error, :enoent} ->
  #       Logger.error("Not Found")
  #       %{conv | status: 404, resp_body: "File not found"}

  #     {:error, reason} ->
  #       Logger.error("#{reason}")
  #       %{conv | status: 500, resp_body: "File error: #{reason}"}
  #   end
  # end

  def emojify(%Conv{status: 200} = conv) do
    %{conv | resp_body: "🎉🎉\n#{conv.resp_body}\n🎉🎉"}
  end

  def emojify(%Conv{} = conv), do: conv

  def format_response(%Conv{} = conv) do
    """
    HTTP/1.1 #{Conv.full_status(conv)}\r
    #{format_response_headers(conv)}\r
    \r
    #{conv.resp_body}
    """
  end

  defp put_content_length(conv) do
    %{
      conv
      | resp_headers: %{conv.resp_headers | "Content-Length" => String.length(conv.resp_body)}
    }
  end

  defp format_response_headers(conv) do
    conv.resp_headers
    |> Enum.sort(:desc)
    |> Enum.map(&"#{elem(&1, 0)}: #{elem(&1, 1)}")
    |> Enum.join("\r\n")
  end
end
