defmodule TodosWeb.UserConfirmationController do
  use TodosWeb, :controller

  alias Todos.Accounts

  def create(conn, %{"user" => %{"email" => email}}) do
    case Accounts.get_user_by_email(email) do
      {:ok, user} ->
        # If the email is found, send the confirmation instructions.
        Accounts.deliver_user_confirmation_instructions(
          user,
          &confirmation_url(conn, &1)
        )
    end

    # Respond with a generic message either way to avoid email enumeration
    json(conn, %{message: "If your email is in our system and it has not been confirmed yet, you will receive an email with instructions shortly."})
  end

  def update(conn, %{"token" => token}) do
    case Accounts.confirm_user(token) do
      {:ok, _} ->
        # Return a success message for a valid confirmation
        json(conn, %{message: "User confirmed successfully."})

      :error ->
        # Handle the error case differently depending on whether the user is signed in
        current_user = conn.assigns[:current_user]
        if current_user && current_user.confirmed_at do
          # No need to send a response as the user is already confirmed.
          json(conn, %{message: "User already confirmed."})
        else
          # If the token is invalid or expired, return an error message
          conn
          |> put_status(:unprocessable_entity)
          |> json(%{error: "User confirmation link is invalid or it has expired."})
        end
    end
  end

  # Helper function to generate the confirmation URL
  defp confirmation_url(conn, token) do
    TodosWeb.Endpoint.url(conn) <> "users/confirm/#{token}"
  end
end
