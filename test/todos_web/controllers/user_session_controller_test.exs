defmodule TodosWeb.UserSessionControllerTest do
  use TodosWeb.ConnCase, async: true

  import Todos.AccountsFixtures

  describe "POST /users/log_in" do
    test "logs the user in", %{conn: conn, user: user} do
      conn =
        post(conn, ~p"/users/log_in", %{
          "user" => %{"email" => user.email, "password" => valid_user_password()}
        })

      assert json_response(conn, 200)["message"] =~ "Welcome back!"
      assert_not is_nil(json_response(conn, 200)["user_id"])
      assert_not is_nil(json_response(conn, 200)["user_token"])
    end

    test "logs the user in with remember me", %{conn: conn, user: user} do
      conn =
        post(conn, ~p"/users/log_in", %{
          "user" => %{
            "email" => user.email,
            "password" => valid_user_password(),
            "remember_me" => "true"
          }
        })

      assert conn.resp_cookies["_todos_web_user_remember_me"]
      assert json_response(conn, 200)["message"] =~ "Welcome back!"
    end

    test "logs the user in with return to", %{conn: conn, user: user} do
      conn =
        conn
        |> init_test_session(user_return_to: "/foo/bar")
        |> post(~p"/users/log_in", %{
          "user" => %{
            "email" => user.email,
            "password" => valid_user_password()
          }
        })

      assert json_response(conn, 302)["redirect_to"] == "/foo/bar"
      assert json_response(conn, 200)["message"] =~ "Welcome back!"
    end

    test "emits error message with invalid credentials", %{conn: conn, user: user} do
      conn =
        post(conn, ~p"/users/log_in", %{
          "user" => %{"email" => user.email, "password" => "invalid_password"}
        })

      assert json_response(conn, 401)["error"] == "Invalid email or password"
    end
  end

  describe "DELETE /users/log_out" do
    test "logs the user out", %{conn: conn, user: user} do
      conn = conn |> log_in_user(user) |> delete(~p"/users/log_out")
      assert json_response(conn, 200)["message"] =~ "Logged out successfully"
    end

    test "succeeds even if the user is not logged in", %{conn: conn} do
      conn = delete(conn, ~p"/users/log_out")
      assert json_response(conn, 200)["message"] =~ "Logged out successfully"
    end
  end
end
