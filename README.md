# PhoenixTest

[![Module Version](https://img.shields.io/hexpm/v/phoenix_test.svg)](https://hex.pm/packages/phoenix_test/)
[![Hex Docs](https://img.shields.io/badge/hex-docs-lightgreen.svg)](https://hexdocs.pm/phoenix_test/)
[![License](https://img.shields.io/hexpm/l/phoenix_test.svg)](https://github.com/germsvel/phoenix_test/blob/main/LICENSE)

PhoenixTest is a testing library that allows you to run your feature tests the
same way regardless of whether your page is a LiveView or a static view.

It also handles navigation between LiveView and static pages seamlessly. So, you
don't have to worry about what type of page you're visiting. Just write the
tests from the user's perspective.

Thus, you can test a flow going from static to LiveView pages and back without
having to worry about the underlying implementation.

This is a sample flow:

```elixir
test "admin can create a user", %{conn: conn} do
  conn
  |> visit("/")
  |> click_link("Users")
  |> fill_form("#user-form", name: "Aragorn", email: "aragorn@dunedan.com")
  |> click_button("Create")
  |> assert_has(".user", "Aragorn")
end
```

Note that PhoenixTest does not handle JavaScript. If you're looking for
something that supports JavaScript, take a look at
[Wallaby](https://hexdocs.pm/wallaby/readme.html).

### Why PhoenixTest?

Lately, if I'm going to have a page that uses some JavaScript, I use LiveView.
If the page is going to be completely static, I use regular controllers +
views/HTML modules.

The problem is that they have _vastly different_ testing strategies.

If I use LiveView, we have a great set of helpers. But if a page is static, we
have to resort to controller testing that relies solely on `html_response(conn,
200) =~ "Page title"` for assertions.

Instead, I'd like to have a unified way of testing Phoenix apps -- when they
don't have JavaScript.

That's where `PhoenixTest` comes in.

It's the one way to test your Phoenix apps regardless of live or static views.

## Setup

PhoenixTest requires Phoenix `1.7+` and LiveView `0.20+`. It may work with
earlier versions, but I have not tested that.

### Installation

Add `phoenix_test` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:phoenix_test, "~> 0.1.0", only: test, runtime: false}
  ]
end
```

### Configuration

In `config/test.exs` specify the endpoint to be used for routing requests:

```elixir
config :phoenix_test, :endpoint, MyApp.Endpoint
```

### Adding a `FeatureCase`

`PhoenixTest` helpers can be included via `import PhoenixTest`.

But since each test needs a `conn` struct to get started, you'll likely want to
set up a few things before that.

To make that easier, it's helpful to create a `FeatureCase` module that can be
used from your tests (replace `MyApp` with your app's name):

```elixir
defmodule MyAppWeb.FeatureCase do
  @moduledoc """
  This module defines the test case to be used by tests that require setting up
  a connection to test feature tests.

  Such tests rely on `PhoenixTest` and also import other functionality to
  make it easier to build common data structures and interact with pages.

  Finally, if the test case interacts with the database, we enable the SQL
  sandbox, so changes done to the database are reverted at the end of every
  test. If you are using PostgreSQL, you can even run database tests
  asynchronously by setting `use MyAppWeb.FeatureCase, async: true`, although
  this option is not recommended for other databases.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      use MyAppWeb, :verified_routes

      import MyAppWeb.FeatureCase

      import PhoenixTest
    end
  end

  setup tags do
    MyApp.DataCase.setup_sandbox(tags)
    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end
end
```

Note that we assume your Phoenix project has a
`MyApp.DataCase.setup_sandbox(tags)` function. If it doesn't, and you want to
use Ecto's Sandbox (highly recommended if you're testing with Ecto), update your
`setup` to this:

```elixir
setup tags do
  pid = Ecto.Adapters.SQL.Sandbox.start_owner!(MyApp.Repo, shared: not tags[:async])
  on_exit(fn -> Ecto.Adapters.SQL.Sandbox.stop_owner(pid) end)
end
```

## Usage

Now, you can create your tests like this:

```elixir
# test/my_app_web/features/admin_can_create_user_test.exs

defmodule MyAppWeb.AdminCanCreateUserTest do
  use MyAppWeb.FeatureCase, async: true

  test "admin can create user", %{conn: conn} do
    conn
    |> visit("/")
    |> click_link("Users")
    |> fill_form("#user-form", name: "Aragorn", email: "aragorn@dunedain.com")
    |> click_button("Create")
    |> assert_has(".user", "Aragorn")
  end
```
