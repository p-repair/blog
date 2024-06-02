---
title: Generalities on the migration to Ash
date: 2024-05-31T00:03:00
draft: false
type: articles
category: technical
tags:
- elixir
- ash
url: /en/articles/generalities-on-the-migration-to-ash
summary: We detail only a few steps on how to install Ash on our project.
---

(p)repair is a project to help people reduce their consumption of products. Firstly, we bet on building a mobile application. You can read more in [the project's manifesto](/en/manifesto).

This article is part of the [Migration to Ash series](/en/articles/migration-to-ash-series). Click for the summary, or just pick what you want here!

---

For more context, read our previous article: **[What strategy to migrate from Phoenix to Ash?](/en/articles/what-strategy-to-migrate-from-phoenix-to-ash/)**

First of all, we need to add Ash to our dependencies, and an extension to manage the data layer. Since we are using a postgresql database, we need AshPostgres. No need for other extensions for now so we don’t install them before we need them.

Note that **(p)repair** is our project name. It is translated to `prepair` in file names, and to `Prepair` in module names.

```elixir
### inside mix.exs file

defp deps do
    [
      # Project dependencies
      {:ash, "~> 3.0"},
      {:ash_postgres, "~> 2.0"},
      […]
    ]
end
```

At this step, we can run `mix deps.get` and then `mix deps.compile`.

Everything is fine.

Now we can add these new dependencies to the `formatter.exs` file.

```elixir
### inside formatter.exs file

[
  import_deps: [
    :ash,
    :ash_postgres,
    […]
  ],
  plugins: […, Spark.Formatter],
  […]
]
```

And we can modify our `lib/prepair/repo.ex` file, to replace :

```elixir
### old version

defmodule Prepair.Repo do
  @moduledoc false

  use Ecto.Repo,
    otp_app: :prepair,
    adapter: Ecto.Adapters.Postgres
end
```

```elixir
### new version supporting AshPostgres

defmodule Prepair.Repo do
  @moduledoc false

  use AshPostgres.Repo,
    otp_app: :prepair

  def installed_extensions do
    ["ash-functions"]
  end
end
```

It should remain fully compatible for all our application interactions with the database, since AshPostgres is using Ecto under the hood, so every Ecto functions used in our code remain valid.

We verify it with a classic:

```
mix test
```

And that's all for this step!

Easy, no? It worth a commit 😃

Read our next article: **[Preparation for the migration from Phoenix to Ash](/en/articles/prepare-the-phoenix-to-ash-migration/)**

---
Guillaume, from the (p)repair team
