defmodule Gecko.Repo do
  use Ecto.Repo,
    otp_app: :gecko,
    adapter: Ecto.Adapters.Postgres
end
