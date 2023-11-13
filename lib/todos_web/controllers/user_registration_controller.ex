defmodule TodosWeb.UserRegistrationController do
  use TodosWeb, :controller

  alias Todos.Accounts
  alias Todos.Accounts.User
  alias TodosWeb.UserAuth

  def create(conn, %{"user" => user_params}) do
    case Accounts.register_user(user_params) do
      {:ok, user} ->
        {:ok, _} =
          Accounts.deliver_user_confirmation_instructions(
            user,
            &confirmation_url(conn, &1)
          )

        conn
        |> put_status(:created) # Set the HTTP status code to 201 (Created)
        |> json(%{message: "User created successfully.", user_id: user.id})

      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_status(:unprocessable_entity) # Set error status code
        |> json(%{error: "Registration failed.", details: changeset.errors})
    end
  end

  # Helper function to generate the confirmation URL
  defp confirmation_url(conn, token) do
    TodosWeb.Endpoint.url(conn) <> "users/confirm/#{token}"
  end
end
