defmodule Gecko.GeckoApi do
  @moduledoc """
  Documentation for `Gecko`.
  It's an adapter for CoinGecko: cryptocurrency prices and market capitalization.
  More information: [Explore API](https://www.coingecko.com/en/api#explore-api)
  """

  defdelegate search(params), to: Gecko.Coins, as: :search
  defdelegate coins_market_chart(params), to: Gecko.Coins, as: :market_chart
end
