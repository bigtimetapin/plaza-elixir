defmodule PlazaWeb.ErrorJSONTest do
  use PlazaWeb.ConnCase, async: true

  test "renders 404" do
    assert PlazaWeb.ErrorJSON.render("404.json", %{}) == %{errors: %{detail: "Not Found"}}
  end

  test "renders 500" do
    assert PlazaWeb.ErrorJSON.render("500.json", %{}) ==
             %{errors: %{detail: "Internal Server Error"}}
  end
end
