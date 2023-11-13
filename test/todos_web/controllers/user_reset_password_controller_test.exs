defmodule TodosWeb.UserResetPasswordControllerTest do
  use TodosWeb.ConnCase, async: true

  alias Todos.Accounts
  alias Todos.Repo
  import Todos.AccountsFixtures

  setup do
    %{user: user_fixture()}
  end

  describe "POST /users/reset_password" do
    @tag :capture_log
    test "sends a new reset password token", %{conn: conn, user: user} do
      conn =
        post(conn, ~p"/users/reset_password", %{
          "user" => %{"email" => user.email}
        })

      assert json_response(conn, 200)["message"] =~
             "If your email is in our system"

      assert Repo.get_by!(Accounts.UserToken, user_id: user.id).context == "reset_password"
    end

    test "does not send reset password token if email is invalid", %{conn: conn} do
      conn =
        post(conn, ~p"/users/reset_password", %{
          "user" => %{"email" => "unknown@example.com"}
        })

      assert json_response(conn, 200)["message"] =~
             "If your email is in our system"

      assert Repo.all(Accounts.UserToken) == []
    end
  end

  describe "PUT /users/reset_password/:token" do
    setup %{user: user} do
      token =
        extract_user_token(fn url ->
          Accounts.deliver_user_reset_password_instructions(user, url)
        end)

      %{token: token}
    end

    test "resets password once", %{conn: conn, user: user, token: token} do
      conn =
        put(conn, ~p"/users/reset_password/#{token}", %{
          "user" => %{
            "password" => "new valid password",
            "password_confirmation" => "new valid password"
          }
        })

      assert json_response(conn, 200)["message"] =~
             "Password reset successfully"
      assert json_response(conn, 200)["user_id"]

      assert_not is_nil(json_response(conn, 200)["user_id"])

      refute get_session(conn, :user_token)
    end

    test "does not reset password on invalid data", %{conn: conn, token: token} do
      conn =
        put(conn, ~p"/users/reset_password/#{token}", %{
          "user" => %{
            "password" => "too short",
            "password_confirmation" => "does not match"
          }
        })

      assert json_response(conn, 422)["error"] == "Password reset failed."
      assert json_response(conn, 422)["details"]["password"] =~ "must be at least"
    end

    test "does not reset password with invalid token", %{conn: conn} do
      conn = put(conn, ~p"/users/reset_password/oops")
      assert json_response(conn, 422)["error"] == "Reset password link is invalid or it has expired"
    end
  end
end
