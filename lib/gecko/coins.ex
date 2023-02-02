defmodule Gecko.Coins do
  @moduledoc false

  alias Gecko.HttpClient

  @type error :: {:error, {:http_error | :request_error, String.t()}}

  @type coins_params :: %{
          required(:id) => String.t(),
          optional(:localization) => String.t(),
          optional(:tickers) => boolean(),
          optional(:market_data) => boolean(),
          optional(:community_data) => boolean(),
          optional(:developer_data) => boolean(),
          optional(:sparkline) => boolean()
        }

  @spec coins(coins_params) :: {:ok, map()} | error
  def coins(params = %{id: id}) do
    params = Map.delete(params, :id)

    HttpClient.get("coins/#{id}", params)
  end

  @spec search(any) ::
          {:error, {:request_error, binary}}
          | {:ok, any()}
  def search(search) do
    HttpClient.get("/search?query=#{search}")
  end

  @type market_chart_params :: %{
          required(:id) => String.t(),
          required(:vs_currency) => String.t(),
          required(:days) => pos_integer(),
          optional(:interval) => String.t()
        }

  @spec market_chart(market_chart_params) :: {:ok, map()} | error
  def market_chart(params = %{id: id}) do
    params = Map.delete(params, :id)

    HttpClient.get("coins/#{id}/market_chart", params)
  end
end
