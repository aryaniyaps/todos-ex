defmodule TodosWeb.UserResetPasswordController do
  use TodosWeb, :controller

  alias Todos.Accounts

  plug :get_user_by_reset_password_token when action in [:edit, :update]

  def create(conn, %{"user" => %{"email" => email}}) do
    if user = Accounts.get_user_by_email(email) do
      Accounts.deliver_user_reset_password_instructions(
        user,
        &reset_password_url(conn, &1)
      )
    end

    conn
    |> put_status(:ok) # Set the HTTP status code
    |> json(%{message: "If your email is in our system, you will receive instructions to reset your password shortly."})
  end

  def update(conn, %{"user" => user_params}) do
    case Accounts.reset_user_password(conn.assigns.user, user_params) do
      {:ok, _} ->
        conn
        |> put_status(:ok) # Set the HTTP status code
        |> json(%{message: "Password reset successfully."})

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity) # Set error status code
        |> json(%{error: "Password reset failed.", details: changeset.errors})
    end
  end

  defp get_user_by_reset_password_token(conn, _opts) do
    %{"token" => token} = conn.params

    if user = Accounts.get_user_by_reset_password_token(token) do
      conn |> assign(:user, user) |> assign(:token, token)
    else
      conn
      |> put_status(:unprocessable_entity) # Set error status code
      |> json(%{error: "Reset password link is invalid or it has expired."})
      |> halt()
    end
  end

  # Helper function to generate the reset password URL
  defp reset_password_url(conn, token) do
    TodosWeb.Endpoint.url(conn) <> "users/reset_password/#{token}"
  end
end
