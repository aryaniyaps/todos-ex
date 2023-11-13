defmodule TodosWeb.UserSettingsController do
  use TodosWeb, :controller

  alias Todos.Accounts
  alias TodosWeb.UserAuth

  plug :assign_email_and_password_changesets

  def update(conn, %{"action" => "update_email"} = params) do
    %{"current_password" => password, "user" => user_params} = params
    user = conn.assigns.current_user

    case Accounts.apply_user_email(user, password, user_params) do
      {:ok, applied_user} ->
        Accounts.deliver_user_update_email_instructions(
          applied_user,
          user.email,
          &url(~p"/users/settings/confirm_email/#{&1}")
        )

        conn
        |> put_status(:ok) # Set the HTTP status code to 200 (OK)
        |> json(%{message: "Email change confirmation link sent successfully"})

      {:error, changeset} ->
        json(conn, %{error: "Failed to update email", changeset: changeset})
    end
  end

  def update(conn, %{"action" => "update_password"} = params) do
    %{"current_password" => password, "user" => user_params} = params
    user = conn.assigns.current_user

    case Accounts.update_user_password(user, password, user_params) do
      {:ok, _user} ->
        conn
        |> put_status(:ok) # Set the HTTP status code to 200 (OK)
        |> json(%{message: "Password updated successfully"})

      {:error, changeset} ->
        json(conn, %{error: "Failed to update password", changeset: changeset})
    end
  end

  def confirm_email(conn, %{"token" => token}) do
    case Accounts.update_user_email(conn.assigns.current_user, token) do
      :ok ->
        conn
        |> put_status(:ok) # Set the HTTP status code to 200 (OK)
        |> json(%{message: "Email changed successfully"})

      :error ->
        json(conn, %{error: "Failed to update email", message: "Email change link is invalid or it has expired."})
    end
  end

  defp assign_email_and_password_changesets(conn, _opts) do
    user = conn.assigns.current_user

    conn
    |> assign(:email_changeset, Accounts.change_user_email(user))
    |> assign(:password_changeset, Accounts.change_user_password(user))
  end
end
