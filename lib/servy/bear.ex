defmodule Servy.Bear do
  defstruct id: nil,
            name: "",
            type: "",
            hibernating: false

  def is_grizzly?(bear) do
    bear.type == "Grizzly"
  end

  def order_asc_by_name(bear_1, bear_2) do
    bear_1.name <= bear_2.name
  end
end
