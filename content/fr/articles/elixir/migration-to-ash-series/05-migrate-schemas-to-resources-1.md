---
title: Migrate Ecto Schemas into Ash Resources (1/3)
date: 2024-05-31T00:05:00
draft: false
type: articles
category: technical
tags:
- elixir
- ash
url: /fr/articles/migrate-ecto-schemas-into-ash-resources-1
summary: Article technique non traduit en français. We give our general comprehension on how Ash works versus Phoenix works.
---
Article technique non traduit en français.

(p)repair is a project to help people reduce their consumption of products. Firstly, we bet on building a mobile application. You can read more in [the project's manifesto](/fr/manifeste).

This article is part of the [Migration to Ash series](/fr/articles/migration-to-ash-series). Click for the summary, or just pick what you want here!

---

For more context, read our previous article: **[Preparation for the migration from Phoenix to Ash](/fr/articles/prepare-the-phoenix-to-ash-migration/)**

This first article on migration Ecto Schemas into Ash Resources will focus on general comprehension of how Ash works versus how Phoenix works, for the basis. Our second article will focus on code example, giving you snippets of our project code, with real Ecto Schemas transformed into real Ash Resources. In our third article we will have a quick look on how to compare our Ash generated migration with our already existing database, and we will see that we need to adapt the migration generated by Ash in our migrating project.

By now we know that:

*   every Ecto Schema should be translated into an Ash Resource
*   every Phoenix context should be translated into an Ash Domain → but we don’t look at functions for now

We will go a bit deeper to be sure we fully understood the differences between Ash and Phoenix. We are not going to talk about the web for now, as we can independently migrate the non-web part and have our application fully working with Ash Resources already. This is what we want first, because we go step by step.

We will take a `Prepair.Products.Category` shema for instance in both worlds here.

## Phoenix framework

Phoenix framework is very handy because it previously autogenerated files for us, when we ran commands such as:

```
phx.gen.context Products Category categories name:string description:string average_lifetime_m:integer
```

So these things were autogenerated for us:

*   the Products context, filled with functions to create, read, update and delete categories
*   the Category Ecto Schema, with
    *   a `name` field, which has a type of `string`
    *   a `description` field, which has a type of `string`
    *   an `average_lifetime_m` field, which has a type of `integer`
    *   a changeset function which collect these 3 fields from parameters when it is called, and put them into Category Schema
*   a create\_categories Ecto Migration file autogenerated, which describes the creation of a table `categories` in the database

Then you have to manually:

*   adjust our Ecto Schema if needed (like adding relations, uniqueness validations in the changeset…)
*   adjust our Ecto Migration file according to our Ecto Schema (like adding relations with foreign keys, unique constraints with indexes…)

And finally we can run the migration with:

```
mix ecto.migrate
```

## Ash framework

For the moment, Ash will not autogenerate contexts (or Domains in Ash “language”), nor schemas (or Resources in Ash ”language") for us.

This is probably a feature to come one day, but today, it doesn’t exist the way it exists with Phoenix.

But Ash is very handy in another way, as it will allow us for instance to use a lot of its “default” features, which corresponds in a sense to the autogenerated create, read, update and delete functions for our Resources. And there are many more crazy features for us after we did the first steps, as generating JSON:API compliant views, and remember, that’s why we are here at the begining!

What do we have to do, to translate the Phoenix process which allowed us to create and migrate a Category Schema?

We have to manually:

*   create a Products Domain, in which we will just declare that it has `resources`, including a Category Resource
*   create a Category Resource, in which we will just declare the `data_layer` (postgres), the `attributes` (think of Ecto Schema fields), the `relations` if they exist, and the `identities` if needed (think of Ecto Changeset unique validations)

Then, we can run:

```
mix ash.codegen create_categories
```

And Ash will autogenerate a migration file named `create_categories.exs` for us.

This is the one key point to understand of the Ash behaviour:

*   we declare our Resources
*   Ash will translate these declarations into a migration

\=> This is nuts, because it ensures our application code is a true representation of our database code!

If we add new `attributes` in you Category Resource, such as an `image` with a `string` type, and then we run:

```
mix ash.codegen add_image_to_categories
```

Ash will autogenerate a new migration file named `add_image_to_categories.ex` with code such as:

```elixir
defmodule Prepair.Repo.Migrations.AddImageToCategories do
  @moduledoc """
  Updates resources based on their most recent snapshots.

  This file was autogenerated with `mix ash_postgres.generate_migrations`
  """

  use Ecto.Migration

  def up do
    alter table(:categories) do
      add :image, :text
    end
  end

  def down do
    alter table(:categories) do
      remove :image
    end
  end
end
```

And of course, we can modify our resources in a more complex way, such as adding relations, constraints, modifying attribute types, etc… Ash will handle all these things and translate them for us in a migration file when we run the command:

```
mix ash.codegen <name_of_the_migration>
```

We could call it “magic”, but it is not, as you can check within Ash code and Ash docs how thing are done. But what’s certain is that it is quite a good way to go!

Then, to run the migration, we have write on the terminal:

```
mix ash.migrate
```

Note that since Ash is using Ecto to manage our database layer, you can still run all Ecto commands in you project as well if you need it / want it!

One other important thing to note is that since Ash will autogenerate migration files for us, from our Resources, we have to declare all kind of relations into these Resources. For instance, it is not needed to have an Ecto Schema representing a join table to handle `many_to_many` relationships. But it is needed to have an Ash Resource representing the join table, to handle such relationships. Each table in our database should be represented by an Ash resource, as long as we want this table to be autogenerated, which means fully aligned from our application code, to our database code.

## Snapshots

To end this article, let’s have a word on snapshots.

In parallel of generating a migration file, the command

```
mix ash.codegen <name_of_the_migration>
```

will also generate `resource_snapshots`.

They can be retrieved by following this path inside our project directory: `priv/resource_snapshots/repo/<name_of_a_resource>`.

What are snapshots? They are like a picture of how our Ash Resources looks like, at the time we ran the `mix ash.codegen` command.

If we run again the same command, we see such an output on the terminal:

```
> mix ash.codegen test_new_migration
Compiling 7 files (.ex)

Generated prepair app
Getting extensions in current project...
Running codegen for AshPostgres.DataLayer...

Extension Migrations:
No extensions to install

Generating Tenant Migrations:

Generating Migrations:
No changes detected, so no migrations or snapshots have been created.
```

What happened?

Ash just compared our Ash Resources with our already existing Resource's snapshots, and saw there are no differences.

A Resource's snapshot looks like this:

```elixir
{
    "attributes": [
        {
            "default": "fragment(\"gen_random_uuid()\")",
            "size": null,
            "type": "uuid",
            "source": "id",
            "references": null,
            "allow_nil?": false,
            "primary_key?": true,
            "generated?": false
        },
        {
            "default": "nil",
            "size": null,
            "type": "integer",
            "source": "average_lifetime_m",
            "references": null,
            "allow_nil?": true,
            "primary_key?": false,
            "generated?": false
        },
        {
            "default": "nil",
            "size": null,
            "type": "string",
            "source": "description",
            "references": null,
            "allow_nil?": true,
            "primary_key?": false,
            "generated?": false
        },
        […]
    ],
    "table": "categories",
    "hash": "BD57EF1021EA9B419368DA0132180C746AE320B02536261EDAB65F2D287FE6DC",
    "identities": [
        {
            "name": "name",
            "keys": [
                "name"
            ],
            "base_filter": null,
            "all_tenants?": false,
            "index_name": "categories_name_index"
        }
    ],
    "repo": "Elixir.Prepair.Repo",
    "custom_statements": [],
    "schema": null,
    "check_constraints": [],
    "custom_indexes": [],
    "multitenancy": {
        "global": null,
        "attribute": null,
        "strategy": null
    },
    "base_filter": null,
    "has_create_action": false
}
```

It takes all relevant information from our Ash Resource definition, and translates it to a JSON file. All relevant information, in this case, are information that represents the existence of a resource in the database (a table, with its indexes and references). These information are mainly described inside the sections `postgres` (or other data\_layer), `attributes`, `relationships` and `identities` of an Ash Resource.

Declaring `actions` inside an Ash Resource will not made any changes occurs in the database for instance, so `actions` are not part of these Resource's snapshots because they don’t need to.

Since we understand better how all that works now, let’s go to work, and in the next article, we will present code snippets of our migration from Ecto Schemas to Ash Resources.

Read our next article: **[Migrate Ecto Schemas into Ash Resources (2/3)](/fr/articles/migrate-ecto-schemas-into-ash-resources-2/)**

---
### References

1.  Get Started With AshPostgres – [https://hexdocs.pm/ash\_postgres/get-started-with-ash-postgres.html](https://ash-hq.org/docs/guides/ash_postgres/latest/tutorials/get-started-with-ash-postgres#get-started-with-postgres)

---
Guillaume, from the (p)repair team
