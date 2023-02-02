defmodule GeckoWeb.PageController do
  use GeckoWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
