defmodule TodosWeb.UserSettingsControllerTest do
  use TodosWeb.ConnCase, async: true

  alias Todos.Accounts
  import Todos.AccountsFixtures

  setup :register_and_log_in_user

  describe "PUT /users/settings (change password form)" do
    test "updates the user password and resets tokens", %{conn: conn, user: user} do
      new_password_conn =
        put(conn, ~p"/users/settings", %{
          "action" => "update_password",
          "current_password" => valid_user_password(),
          "user" => %{
            "password" => "new valid password",
            "password_confirmation" => "new valid password"
          }
        })

      assert conn.status == 200

      assert json_response(new_password_conn, 200) == %{"message" => "Password updated successfully"}

      assert Accounts.get_user_by_email_and_password(user.email, "new valid password")
    end

    test "does not update password on invalid data", %{conn: conn} do
      old_password_conn =
        put(conn, ~p"/users/settings", %{
          "action" => "update_password",
          "current_password" => "invalid",
          "user" => %{
            "password" => "too short",
            "password_confirmation" => "does not match"
          }
        })

      response = json_response(old_password_conn, 200)

      assert Map.get(response, "error") == "Failed to update password"
      assert Map.get(response, "changeset") != nil
    end
  end

  describe "PUT /users/settings (change email form)" do
    @tag :capture_log
    test "updates the user email", %{conn: conn, user: user} do
      conn =
        put(conn, ~p"/users/settings", %{
          "action" => "update_email",
          "current_password" => valid_user_password(),
          "user" => %{"email" => unique_user_email()}
        })

      assert conn.status == 200

      assert json_response(conn, 200) == %{"message" => "Email change confirmation link sent successfully"}

      refute Accounts.get_user_by_email(user.email)
    end

    test "does not update email on invalid data", %{conn: conn} do
      conn =
        put(conn, ~p"/users/settings", %{
          "action" => "update_email",
          "current_password" => "invalid",
          "user" => %{"email" => "with spaces"}
        })

      response = json_response(conn, 200)

      assert Map.get(response, "error") == "Failed to update email"
      assert Map.get(response, "changeset") != nil
    end
  end
end
