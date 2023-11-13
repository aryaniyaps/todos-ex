defmodule TodosWeb.UserSessionController do
  use TodosWeb, :controller

  alias Todos.Accounts
  alias TodosWeb.UserAuth

  def create(conn, %{"user" => user_params}) do
    %{"email" => email, "password" => password} = user_params

    if user = Accounts.get_user_by_email_and_password(email, password) do
      conn
      |> put_status(:ok) # Set the HTTP status code to 200 (OK)
      |> json(%{message: "Welcome back!", user_id: user.id})

    else
      conn
      |> put_status(:unauthorized) # Set unauthorized status code
      |> json(%{error: "Invalid email or password"})
    end
  end

  def delete(conn, _params) do
    conn
    |> put_status(:ok) # Set the HTTP status code to 200 (OK)
    |> json(%{message: "Logged out successfully."})
    |> UserAuth.log_out_user()
  end
end
