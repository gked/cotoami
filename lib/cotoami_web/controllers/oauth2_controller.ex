defmodule CotoamiWeb.OAuth2Controller do
  use CotoamiWeb, :controller
  require Logger
  alias Cotoami.AmishiService
  alias CotoamiWeb.AuthPlug
  alias CotoamiWeb.OAuth2.Google

  def index(conn, %{"provider" => provider}) do
    redirect conn, external: authorize_url!(provider)
  end

  def callback(conn, %{"provider" => provider, "code" => code}) do
    client = get_token!(provider, code)
    user = get_user!(provider, client)
    Logger.info "OAuth2 user: #{inspect user}"
    amishi = AmishiService.insert_or_update!(user)
    conn
    |> AuthPlug.start_session(amishi)
    |> put_session(:access_token, client.token.access_token)
    |> redirect(to: "/")
  end

  defp authorize_url!("google"), do: Google.authorize_url!(scope: "https://www.googleapis.com/auth/userinfo.email")
  defp authorize_url!(_), do: raise "No matching provider available"

  defp get_token!("google", code), do: Google.get_token!(code: code)
  defp get_token!(_, _), do: raise "No matching provider available"

  defp get_user!("google", client), do: Google.get_user!(client)
end
