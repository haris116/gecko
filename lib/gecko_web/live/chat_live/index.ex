defmodule GeckoWeb.ChatLive.Index do
  use GeckoWeb, :live_view
  alias Gecko.Accounts
  alias Gecko.GeckoApi

  def mount(_params, %{"user_token" => user_token}, socket) do
    socket =
      assign_new(socket, :current_user, fn ->
        Accounts.get_user_by_session_token(user_token)
      end)
      |> assign(coin_option: nil)

    if connected?(socket) do
      GeckoWeb.Endpoint.subscribe(topic())
    end

    {:ok, init_gecko(socket)}
  end

  def handle_event("send", %{"text" => text}, socket) do
    GeckoWeb.Endpoint.broadcast(topic(), "message", %{text: text, name: socket.assigns.username})
    send(self(), "get_coin")
    {:noreply, socket}
  end

  def handle_event("option", %{"id" => "name", "value" => ""}, socket) do
    socket = update_form(socket, "name")

    {
      :noreply,
      socket
      |> assign(
        messages:
          socket.assigns.messages ++
            [
              %{name: "GeckoBot", text: render_from(socket.assigns)},
              %{text: "Enter coin name", name: "GeckoBot"}
            ]
      )
    }
  end

  def handle_event("option", %{"id" => "id", "value" => ""}, socket) do
    socket = update_form(socket, "id")

    {:noreply,
     socket
     |> assign(
       messages:
         socket.assigns.messages ++
           [
             %{name: "GeckoBot", text: render_from(socket.assigns)},
             %{text: "Enter coin id", name: "GeckoBot"}
           ]
     )}
  end

  def handle_event("get_coin_info", %{"coin_name" => _coin, "id" => id}, socket) do
    send(self(), {"render", id})

    {:noreply, socket}
  end

  def handle_info({"render", id}, socket) do
    chart_data =
      GeckoApi.coins_market_chart(%{
        id: id,
        vs_currency: "usd",
        days: 14,
        interval: "daily"
      })
      |> case do
        {:ok, result} ->
          result
          |> Map.get("prices")
          |> IO.inspect(label: "prices")
          |> Enum.reduce([], fn [epoch, price], acc ->

            acc ++ [[DateTime.from_unix!(epoch, :millisecond) |> DateTime.to_date() |> Date.to_string(), price]]
          end)

        _ ->
          []
      end

    {:noreply,
     socket
     |> assign(
       messages:
         socket.assigns.messages ++
           [
             %{
               name: "GeckoBot",
               text:
                 render_market_chart(socket, chart_data)
             }
           ]
     )}
  end

  def handle_info(%{event: "message", payload: message}, socket) do
    {:noreply, assign(socket, messages: socket.assigns.messages ++ [message])}
  end

  def handle_info("get_coin", socket) do
    {:noreply, get_coin_info(socket)}
  end

  def render_from(assigns) do
    ~H"""
    <button phx-click="option" phx-value-id="id" disabled={@coin_option}>
      By Id
    </button>
    <button phx-click="option" phx-value-id="name" disabled={@coin_option}>
      By Name
    </button>
    """
  end

  def render_coin_options(assigns, coin_list) do
    ~H"""
    <div>
      <%= for {coin, id} <- coin_list do %>
        <button phx-click="get_coin_info" phx-value-coin_name={coin} phx-value-id={id}>
          <%= coin %>
        </button>
        <br/>
      <% end %>
    </div>
    """
  end

  def render_market_chart(assigns, []),
    do: ~H"""
    <p style="margin: 2px;"><b>"GeckoBot:"</b>: "No Data found for data"</p>
    """

  def render_market_chart(assigns, coin_history) do
    ~H"""
    <div id="chart" phx-update="ignore" phx-hook="RenderChart">
      <%= Poison.encode!(coin_history)
      |> Chartkick.line_chart()
      |> Phoenix.HTML.raw() %>
    </div>
    """
  end

  def init_gecko(socket) do
    name = socket.assigns.current_user.first_name

    socket
    |> assign(username: name)
    |> assign(
      messages: [
        %{name: "GeckoBot", text: "Welcome " <> name},
        %{name: "GeckoBot", text: "Do you want to search coins by name or by ID?"},
        %{name: "GeckoBot", text: render_from(socket.assigns)}
      ]
    )
    |> assign(coin_option: nil)
  end

  defp update_form(socket, option) do
    discard =
      socket.assigns.messages
      |> List.last()

    messages = socket.assigns.messages -- [discard]

    socket
    |> assign(messages: messages)
    |> assign(coin_option: option)
  end

  defp get_coin_info(socket) do
    search_param =
      socket.assigns.messages
      |> Enum.filter(&(&1.name != "GeckoBot"))
      |> List.first()

    if socket.assigns.coin_option == "id" do
      GeckoApi.search(search_param.text)
      |> handle_response(socket)
    else
      GeckoApi.search(search_param.text)
      |> handle_response(socket)
    end
  end

  def handle_response(response, socket) do
    response
    |> case do
      {:ok, result} ->
        coin_list =
          result
          |> Map.get("coins")
          |> Enum.take(5)
          |> Enum.map(&{Map.get(&1, "name"), Map.get(&1, "id")})

        assign(socket,
          messages:
            socket.assigns.messages ++
              [%{name: "GeckoBot", text: render_coin_options(socket.assigns, coin_list)}]
        )

      _ ->
        assign(socket,
          messages:
            socket.assigns.messages ++
              [%{name: "GeckoBot", text: "Could not find the coin"}]
        )
    end
  end

  defp topic do
    "chat"
  end
end
