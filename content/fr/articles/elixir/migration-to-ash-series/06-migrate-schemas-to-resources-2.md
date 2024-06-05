---
title: Migrate Ecto Schemas into Ash Resources (2/3)
date: 2024-05-31T00:06:00
draft: false
type: articles
category: technical
tags:
- elixir
- ash
url: /fr/articles/migrate-ecto-schemas-into-ash-resources-2
summary: Article technique non traduit en français. We give code examples to migrate an Ecto Schema into an Ash Resource.
---
Article technique non traduit en français.

(p)repair is a project to help people reduce their consumption of products. Firstly, we bet on building a mobile application. You can read more in [the project's manifesto](/fr/manifeste).

This article is part of the [Migration to Ash series](/fr/articles/migration-to-ash-series). Click for the summary, or just pick what you want here!

---

For more context, read our previous article: **[Migrate Ecto Schemas into Ash Resources (1/3)](/fr/articles/migrate-ecto-schemas-into-ash-resources-1/)**

To recap, our goal now is translate all our Ecto Schemas into Ash Resources.

It has to be done the good way, that means if we go in a brand new Ash project, we paste inside all our Ash Resources, when we will run the command

```
mix ash.codegen <name_of_the_migration>
```

and then the command

```
mix ash.migrate
```

we should obtain a database with the same tables, indexes and references than our current project database, in its state before the migration to Ash.

## Code snippets and comments

We will go together with our real Ecto Schemas.

As we will not copy all our Schemas in this post, we will take our Product example.

Our Ecto Schema Product is located at this path: `lib/prepair/legacy_contexts/products/product.ex`

If you read our previous [Add “legacy\_contexts” and “ash\_domains” folders]((p)repair / Blog / Migration to Ash series / Add “legacy_contexts” and “ash_domains” folders) article, you should understand.

And we create our new Ash Resource Product at this path: `lib/prepair/ash_domains/products/product.ex`

### Ecto Schema example

Now lets see how looks like our Ecto Schema Product.

Note it is quite verbose at some times, because I like doing it to understand what I do, and maybe later I cut off some code lines that represents default options.

```elixir
defmodule Prepair.LegacyContexts.Products.Product do
  use Ecto.Schema

  alias Prepair.LegacyContexts.Notifications.NotificationTemplate
  alias Prepair.LegacyContexts.Products.{Manufacturer, Category, Part}
  alias Prepair.LegacyContexts.Profiles.Ownership

  import Ecto.Changeset

  @required_fields [
    :category_id,
    :manufacturer_id,
    :name,
    :reference
  ]

  @fields @required_fields ++
            [
              :part_ids,
              :notification_template_ids,
              :description,
              :image,
              :average_lifetime_m,
              :country_of_origin,
              :start_of_production,
              :end_of_production
            ]

  @derive {Phoenix.Param, key: :id}
  @primary_key {:id, Ecto.UUID, autogenerate: false}
  schema "products" do
    belongs_to :category, Category,
      foreign_key: :category_id,
      references: :id,
      type: Ecto.UUID

    belongs_to :manufacturer, Manufacturer,
      foreign_key: :manufacturer_id,
      references: :id,
      type: Ecto.UUID

    many_to_many :parts, Part,
      join_through: "product_parts",
      join_keys: [product_id: :id, part_id: :id],
      on_replace: :delete

    many_to_many :notification_templates, NotificationTemplate,
      join_through: "product_notification_templates",
      join_keys: [product_id: :id, notification_template_id: :id],
      on_replace: :delete

    has_many :ownerships, Ownership,
      foreign_key: :product_id,
      references: :id

    field :part_ids, {:array, Ecto.UUID}, virtual: true, default: []

    field :notification_template_ids, {:array, Ecto.UUID},
      virtual: true,
      default: []

    field :average_lifetime_m, :integer
    field :country_of_origin, :string
    field :description, :string
    field :end_of_production, :date
    field :image, :string
    field :name, :string
    field :reference, :string
    field :start_of_production, :date

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(product, attrs) do
    product
    |> cast(attrs, @fields)
    |> validate_required(@required_fields)
    |> unique_constraint([:reference, :manufacturer_id])
  end
end
```

### Ecto Migration example

I will also put in here our Ecto Migration file which corresponds to this Product creation in our database, a while ago.

Why do I put this file here? Because some information it contains are NOT part of the Ecto Schema, but they will have to be part of our Ash Resource, because don’t forget it, Ash will generate future migrations for us from our Resource definitions, so everything that occurred by the past in the database have to be translated into our Ash Resources. In short terms, **we want our Ash Resources to be aligned with our already existing database definitions**.

```elixir
defmodule Prepair.Repo.Migrations.CreateProducts do
  use Ecto.Migration

  def change do
    create table(:products) do
      add :name, :string
      add :reference, :string
      add :description, :string
      add :image, :string
      add :average_lifetime_m, :integer
      add :country_of_origin, :string
      add :start_of_production, :date
      add :end_of_production, :date
      add :manufacturer_id, references(:manufacturers, on_delete: :delete_all)
      add :category_id, references(:categories, on_delete: :delete_all)

      timestamps(type: :utc_datetime)
    end

    create unique_index(:products, [:reference, :manufacturer_id])
    create index(:products, [:name])
    create index(:products, [:manufacturer_id])
    create index(:products, [:category_id])
  end
end
```

### Ash Resource example

#### Start of the description

To start the migration of this Ecto Schema, into an Ash Resource, we will start at the basis:

```elixir
defmodule Prepair.AshDomains.Products.Product do
  use Ash.Resource,								### <- We start by declaring our module as an Ash Resource
    domain: Prepair.AshDomains.Products,		### <- We also need to say which Domain will manage this Resource,
    											###		think of a Phoenix Context, it’s a kind of "API"
    data_layer: AshPostgres.DataLayer			### <- Then, we need to define our data layer, which for us is
    											###		AshPostgres

  alias Prepair.AshDomains.Notifications.{		### <- All the rest are just the same aliases we used before
    NotificationTemplate,
    ProductNotificationTemplates
  }

  alias Prepair.AshDomains.Products.{Category, Manufacturer, Part, ProductParts}
  alias Prepair.AshDomains.Profiles.Ownership
```

#### postgres section

Now, we can add our first section, corresponding to our `data_layer`, so in our case it is `postgres`.

```elixir
defmodule Prepair.AshDomains.Products.Product do
  use Ash.Resource,
    domain: Prepair.AshDomains.Products,
    data_layer: AshPostgres.DataLayer

  alias Prepair.AshDomains.Notifications.{
    NotificationTemplate,
    ProductNotificationTemplates
  }

  alias Prepair.AshDomains.Products.{Category, Manufacturer, Part, ProductParts}
  alias Prepair.AshDomains.Profiles.Ownership

  postgres do										### <- This is the start of our 'postgres' section
    table "products"								### <- This is the name of our table. You can see it’s the
    												### 	same as it was defined in our Ecto Migration file.
    repo Prepair.Repo								### <- This defines which database repository to use

    references do									### <- This is the start of the references sub-section
      reference :category, on_delete: :delete		### <- This is a reference description
      reference :manufacturer, on_delete: :delete
    end												### <- This is the end of the references sub-section

    custom_indexes do								### <- This is the start of the custom_indexes sub-section
      index :category_id, unique: false				### <- This is an index description
      index :manufacturer_id, unique: false
      index :name, unique: false					### <- This is the end of the custom_indexes sub-section
    end

    migration_types average_lifetime_m: :integer,	### <- The migration_types sub-section allow us to describe
                    country_of_origin: :string,		### 	which ecto type we want for which Ash Resource attribute
                    description: :string,
                    image: :string,
                    name: :string,
                    reference: :string
  end												### <- This is the end of our 'postgres' section
```

##### references

About the reference description, we needed to put it here because we wanted to add the `on_delete: :delete` which translates to an `ON DELETE CASCADE` on postgres language.

You can visit these 3 links from the official documentation for more information on how to manage references:

*   References – [https://hexdocs.pm/ash\_postgres/references.html](https://hexdocs.pm/ash_postgres/references.html)
*   DSL: AshPostgres.DataLayer – postgres.references – [https://hexdocs.pm/ash\_postgres/dsl-ashpostgres-datalayer.html#postgres-references](https://hexdocs.pm/ash_postgres/references.html)
*   DSL: AshPostgres.DataLayer – postgres.references.reference – [https://hexdocs.pm/ash\_postgres/dsl-ashpostgres-datalayer.html#postgres-references-reference](https://hexdocs.pm/ash_postgres/references.html)

Note that we will later define the `relationship` section, in which we will be able to define the foreign keys etc…

We can add other options to a reference description if needed.

##### custom\_indexes

We only have to define non-unique indexes inside this section, or maybe more complex indexes if needed.

Unique indexes can be managed under the `identities` section that we will look at the end of this article.

Doc about custom indexes is located [here](https://hexdocs.pm/ash_postgres/dsl-ashpostgres-datalayer.html#postgres-custom_indexes). 

##### migration\_types

About the migration\_types, it is a bit tricky here. We have an already existing database with `:string` Ecto types which had been translated into `:character varying(255)` inside our postgresql database.

The [Ecto primitive types](https://hexdocs.pm/ecto/Ecto.Schema.html#module-primitive-types) doesn’t translate exactly in the same way as the [Ash built in types](https://hexdocs.pm/ash/Ash.Type.html#module-built-in-types) will translate.

[Here](https://hexdocs.pm/ecto/Ecto.Schema.html#module-primitive-types) are some documentation about how Ecto primitive types are mapped to the appropriate database type.

In most cases, this is not so much important, but because we are in a migration process from a framework to another, we need at first to comply with what has already been done on our project, including our database. Be compliant now will make the review much easier when we will later compare database schemas to ensure our migration is proper.

We can assume a few differences from our legacy database, but the less they are, the easier will be the comparison.

To your knowledge just be aware that:

*   `:string` Ecto Type → `character varying(255)` in postgresql
*   `:string` Ash Type → `text` in postgresql
*   `:integer` Ecto Type → `integer` in postgresql
*   `:integer` Ash Type → `bigint` in postgresql

There are probably other different conversions, but that’s the ones we've noticed in our project's migration.

It is also possible to define your own custom types in Ash, if you really need something more specific.

#### attributes section

```elixir
defmodule Prepair.AshDomains.Products.Product do
  use Ash.Resource,
    domain: Prepair.AshDomains.Products,
    data_layer: AshPostgres.DataLayer

  alias Prepair.AshDomains.Notifications.{
    NotificationTemplate,
    ProductNotificationTemplates
  }

  alias Prepair.AshDomains.Products.{Category, Manufacturer, Part, ProductParts}
  alias Prepair.AshDomains.Profiles.Ownership

  require Ash.Query

  postgres do
    table "products"
    repo Prepair.Repo

    references do
      reference :category, on_delete: :delete
      reference :manufacturer, on_delete: :delete
    end

    custom_indexes do
      index :category_id, unique: false
      index :manufacturer_id, unique: false
      index :name, unique: false
    end

    migration_types average_lifetime_m: :integer,
                    country_of_origin: :string,
                    description: :string,
                    image: :string,
                    name: :string,
                    reference: :string
  end

  attributes do											### <- This is the start of our 'attributes' section
    uuid_primary_key :id								### <- This describes a primary key attribute, with a key
    													###		named :id
    attribute :average_lifetime_m, :integer
    attribute :country_of_origin, :string
    attribute :description, :string
    attribute :end_of_production, :date
    attribute :image, :string
    attribute :name, :string, allow_nil?: false			### <- This describes an attribute with a key :name
    													### 	which is of :string type, and cannot be nullable
    attribute :reference, :string, allow_nil?: false
    attribute :start_of_production, :date
    create_timestamp :inserted_at, type: :utc_datetime
    update_timestamp :updated_at, type: :utc_datetime
  end													### <- This is the end of our 'attributes' section
```

`attributes` in an Ash Resource are the equivalent of `fields` in an Ecto Schema, except you don’t declare any relations inside this section, because there is a dedicated section for them that we will see just after.

The main principle it that inside this section, you define all your Resource attributes (except relations), and it is done like that:
`attribute <key_name>, <type>, <options…>`

If there are many options, you can write it like:

```elixir
attributes do
	attribute <key_name>, <type> do
		<option_1_key> <option_1_value>
		<option_2_key> <option_2_value>
		<option_3_key> <option_3_value>
		…
	end
end
```

Ash defines 4 ‘special attributes’, and we can find documentation on them [here](https://hexdocs.pm/ash/attributes.html#special-attributes).

Basically, it’s attributes we need in a lot of cases:

*   `uuid_primary_key` → postgresql `uuid` type, not nullable, default to `gen_random_uuid()`
*   `integer_primary_key` → postgresql `bigint` type, not nullable, default to `nextval('<table_name>_id_seq'::regclass)`. Ash documentation do not recommend using auto-incrementing integer ids, but uuid instead, linking to explanations on it.
*   `create_timestamp` → postgresql `timestamp without time zone` type, not nullable, default to `(now() AT TIME ZONE 'utc'::text)`
*   `update_timestamp` → postgresql `timestamp without time zone` type, not nullable, default to `(now() AT TIME ZONE 'utc'::text)`

Look at these documentation pages for more explanations about attributes:

*   Attributes – [https://hexdocs.pm/ash/attributes.html](https://hexdocs.pm/ash/attributes.html)
*   DSL: Ash.Resource.Dsl – attributes – [https://hexdocs.pm/ash/dsl-ash-resource.html#attributes](https://hexdocs.pm/ash/dsl-ash-resource.html#attributes)
*   DSL: Ash.Resource.Dsl – attributes.attribute – [https://hexdocs.pm/ash/dsl-ash-resource.html#attributes-attribute](https://hexdocs.pm/ash/dsl-ash-resource.html#attributes-attribute)

#### relationship section

Now that we've described our Resource inside the `postgres` and `attributes` sections, we can move on the `relationships`!

```elixir
defmodule Prepair.AshDomains.Products.Product do
  use Ash.Resource,
    domain: Prepair.AshDomains.Products,
    data_layer: AshPostgres.DataLayer

  alias Prepair.AshDomains.Notifications.{
    NotificationTemplate,
    ProductNotificationTemplates
  }

  alias Prepair.AshDomains.Products.{Category, Manufacturer, Part, ProductParts}
  alias Prepair.AshDomains.Profiles.Ownership

  require Ash.Query

  postgres do
    table "products"
    repo Prepair.Repo

    references do
      reference :category, on_delete: :delete
      reference :manufacturer, on_delete: :delete
    end

    custom_indexes do
      index :category_id, unique: false
      index :manufacturer_id, unique: false
      index :name, unique: false
    end

    migration_types average_lifetime_m: :integer,
                    country_of_origin: :string,
                    description: :string,
                    image: :string,
                    name: :string,
                    reference: :string
  end

  attributes do
    uuid_primary_key :id
    attribute :average_lifetime_m, :integer
    attribute :country_of_origin, :string
    attribute :description, :string
    attribute :end_of_production, :date
    attribute :image, :string
    attribute :name, :string, allow_nil?: false
    attribute :reference, :string, allow_nil?: false
    attribute :start_of_production, :date
    create_timestamp :inserted_at, type: :utc_datetime
    update_timestamp :updated_at, type: :utc_datetime
  end

  relationships do											### <- This is the start of the relationships section
    belongs_to :category, Category do						### <- This is a belongs_to relationship description
      source_attribute :category_id
      destination_attribute :id
      allow_nil? false
    end

    belongs_to :manufacturer, Manufacturer do
      source_attribute :manufacturer_id
      destination_attribute :id
      allow_nil? false
    end

    many_to_many :parts, Part do							### <- This is a many_to_many relationship description
      through ProductParts
      source_attribute_on_join_resource :product_id
      destination_attribute_on_join_resource :part_id
    end

    has_many :ownerships, Ownership do						### <- This is a has_many relationship description
      source_attribute :id
      destination_attribute :product_id
    end

    many_to_many :notification_templates, NotificationTemplate do
      through ProductNotificationTemplates
      source_attribute_on_join_resource :product_id
      destination_attribute_on_join_resource :notification_template_id
    end
  end														### This is the end of the relationships section
```

##### belongs\_to

These relationships are mostly easy to understand.

`belongs_to` relationships will translates to `references` in the database:

```
### Sample from the table "products" in our database

Foreign-key constraints:
    "products_category_id_fkey" FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE CASCADE
```

The `ON DELETE CASCADE` has been defined in the `postgres` `references` su-section as we explained earlier on this article.

The foreign key `category_id` is described here as the `source_attribute`.

The `source_attribute` will create an attribute on the current Resource. We could have omit them in our Resource description, as they default to the value we put, but as I mentioned before, I like to be verbose sometimes to fully understand what I’m doing.

The `destination attribute` is the attribute from the Category Resource for instance, that will be fetched to populate the source attribute.

To keep the Category relationship example, the `category_id` attribute will be populated with the `:id` value from the Category we want to attach to that Product.

Note an important thing: by default, `belongs_to` relationships are nullable. If we want to be certain that each Product will always have an attached Category and Manufacturer for instance, we have to precise that we don’t want these relations to be nullable with the option `allow_nil?` set to `false`.

##### has\_many

We can define this Category relationship through a `has_many` description inside the Category Resource, but it’s not an obligation, as it will change nothing on the database definition that will be generated. But it is still useful for some actions we would like to create later under the Category Resource.

```elixir
### Inside the Prepair.AshDomains.Products.Category Resource

  relationships do
    has_many :products, Product do
      source_attribute :id
      destination_attribute :category_id
    end
```

But remember that all the database logic from `belongs_to` relations is handled by the Resource that **belongs** **to** the other, and not by the Resource which has many. In this detailed example case, all the logic is handled by the Product Resource.

##### has\_one

It follows the same logical as `has_many` relations: you put it in a Resource in front of a Resource with a `belongs_to` statememt.

Inside the Resource which has a `has_one` relationship with one other, you define it like:

```elixir
### If Product had a `has_one` relationship with a resource named OtherResource
### We would represent it like so in the Product Resource:

  relationships do
    has_one :other_resource, OtherResource do
      source_attribute :id
      destination_attribute :other_resource_id
    end
  end
```

##### many\_to\_many

`many_to_many` relationships can sometimes be a bit more challenging, but their implementation remain simple in most cases when you understand what to do.

Our Products Resource for instance is linked to a Parts Resource in a `many_to_many` way.

First of all, as we did in the Ecto Schema, we have to define the join table which will associate many `product_id`s with many `part_id`s.

But as we have already explained a few times, what differentiates Ash is that it will autogenerate migration files based on our Resources descriptions. All our database tables / schemas should be represented by Ash Resources. As the join table exists in our database and can be modified, it also have to exist inside an Ash Resource.

Here is how looks like our Ash Resource which represents the join table between our Product and our Part Resources:

```elixir
defmodule Prepair.AshDomains.Products.ProductParts do
  use Ash.Resource,
    domain: Prepair.AshDomains.Products,
    data_layer: AshPostgres.DataLayer

  alias Prepair.AshDomains.Products.{Product, Part}

  postgres do
    table "product_parts"
    repo Prepair.Repo

    references do
      reference :product, on_delete: :delete
      reference :part, on_delete: :delete
    end

    custom_indexes do
      index :product_id, unique: false
      index :part_id, unique: false
    end
  end

  relationships do
    belongs_to :product, Product do
      source_attribute :product_id
      destination_attribute :id
      primary_key? true
      allow_nil? false
    end

    belongs_to :part, Part do
      source_attribute :part_id
      destination_attribute :id
      primary_key? true
      allow_nil? false
    end
  end
end
```

In this table, we have simple `belongs_to` relationships. It is something that we already seen above so it should be easier to understand now.

However there is one detail here: both `belongs_to` relationships have the `primary_key` option set to `true`. That means the table will have a composite primary key, build from a `product_id` and a `part_id`. This ensures there can have many times the same `product_id` in the table, and there can have many times the same `part_id` in the table (none of them are independently a primary key here). But this also ensure there can have only one time a record with the same `product_id` and `part_id` together. That’s the definition of a `many_to_many` relationship, so we're good!

Note that we could have achieve this description of a `many_to_many` relation in another way: without setting any primary key on that Resource, but with a unique index regrouping `product_id` and `part_id` that we could define through an `identity`. This is the last section we will cover in this article so stay tuned a little more. But this strategy relying on a unique index could block us later if we want to add actions directly on this Resource representing the join table. It is a bit early to talk about that, but keep in mind this other way could later impose limitations (well, you could still modify the join Resource at this moment also…).

Just to get back on the `many_to_many` description in our Product Resource, it also describes 2 keys:

```elixir
    many_to_many :parts, Part do
      through ProductParts
      source_attribute_on_join_resource :product_id
      destination_attribute_on_join_resource :part_id
    end
```

These keys are not directly mentioning the other related Resource (Part) itself, but the join table Resource.

Logically:

*   the source (= Product) attribute on the join Resource is named `product_id`.
*   the destination (= Part) attribute on the join Resource is named `part_id`.

Inside the join Resource, we see that `product_id` is used in a `belongs_to` relation to the Product Resource, and that it will be populated with the destination (= Product) `id` value.

Inside the join Resource, we see that `part_id` id used in a `belongs_to` relation to the Part Resource, and that it will be populated with the destination (= Part) `id` value.

We're done for now with relationships, yeah :)

If you want to explore this subject further, there are good resources accessible at these links:

*   Elixir, Phoenix and Ash blog by Stefan Wintermeyer – Relationships – [https://elixir-phoenix-ash.com/ash/relationships/index.html](https://elixir-phoenix-ash.com/ash/relationships/index.html)
*   Relationships in Ash Guides – [https://hexdocs.pm/ash/relationships.html](https://hexdocs.pm/ash/relationships.html)
*   DSL: Ash.Resource.Dsl – [https://hexdocs.pm/ash/dsl-ash-resource.html#relationships](https://hexdocs.pm/ash/dsl-ash-resource.html#relationships)

The last link will give you all options you can use for declaring relationships.

#### identities section

This is the last section we need to fully translate our “products” table (in the database) to an Ash Product Resource.

Identities allow to describe unique indexes / constraints for attributes of our Resource.

We can also declare them in the `postgres` section, under the `custom_indexes` sub-section, but the [AshPostgres documentation](https://hexdocs.pm/ash_postgres/dsl-ashpostgres-datalayer.html#postgres-custom_indexes) explains that:

> In general, prefer to use `identities` for simple unique constraints. This is a tool to allow for declaring more complex indexes.

This is probably because `identities` will then allow us to get a Resource through the attributes we passed inside this section, directly with the `Ash.get/3` function, but we don’t focus on functions nor actions for this part of our migration process.

Well, the rule to know is: if we just have a unique constraint to declare, just use `identities`.

```elixir
defmodule Prepair.AshDomains.Products.Product do
  use Ash.Resource,
    domain: Prepair.AshDomains.Products,
    data_layer: AshPostgres.DataLayer

  alias Prepair.AshDomains.Notifications.{
    NotificationTemplate,
    ProductNotificationTemplates
  }

  alias Prepair.AshDomains.Products.{Category, Manufacturer, Part, ProductParts}
  alias Prepair.AshDomains.Profiles.Ownership

  require Ash.Query

  postgres do
    table "products"
    repo Prepair.Repo

    references do
      reference :category, on_delete: :delete
      reference :manufacturer, on_delete: :delete
    end

    custom_indexes do
      index :category_id, unique: false
      index :manufacturer_id, unique: false
      index :name, unique: false
    end

    migration_types average_lifetime_m: :integer,
                    country_of_origin: :string,
                    description: :string,
                    image: :string,
                    name: :string,
                    reference: :string
  end

  attributes do
    uuid_primary_key :id
    attribute :average_lifetime_m, :integer
    attribute :country_of_origin, :string
    attribute :description, :string
    attribute :end_of_production, :date
    attribute :image, :string
    attribute :name, :string, allow_nil?: false
    attribute :reference, :string, allow_nil?: false
    attribute :start_of_production, :date
    create_timestamp :inserted_at, type: :utc_datetime
    update_timestamp :updated_at, type: :utc_datetime
  end

  relationships do
    belongs_to :category, Category do
      source_attribute :category_id
      destination_attribute :id
      allow_nil? false
    end

    belongs_to :manufacturer, Manufacturer do
      source_attribute :manufacturer_id
      destination_attribute :id
      allow_nil? false
    end

    many_to_many :parts, Part do
      through ProductParts
      source_attribute_on_join_resource :product_id
      destination_attribute_on_join_resource :part_id
    end

    has_many :ownerships, Ownership do
      source_attribute :id
      destination_attribute :product_id
    end

    many_to_many :notification_templates, NotificationTemplate do
      through ProductNotificationTemplates
      source_attribute_on_join_resource :product_id
      destination_attribute_on_join_resource :notification_template_id
    end
  end

  identities do
    identity :reference_manufacturer_id, [:reference, :manufacturer_id]		### <- Declaration of an identity
  end
end
```

Yeah !!

Now our Product Resource fully describes all the characteristics that were already described in our database, so we can say this Resource is fully migrated, from its database definition! We will see how to verify it soon.

We just give a word on the identity description: here we are saying that the couple of `product.reference` and `product.manufacturer_id` attributes should be unique. That means only one Product can exist with that reference and that manufacturer.

The migration will then generate an index like:

```
### Sample from the table "products" in our database

Indexes:
    "products_reference_manufacturer_id_index" UNIQUE, btree (reference, manufacturer_id)
```

If we wanted to say for instance that each Product should have a unique name, we would have simply described it as:

```elixir
  identities do
    identity :name, [:name]
  end
```

And it would have generate an index like:

```
Indexes:
    "products_name_index" UNIQUE, btree (name)
```

The pattern to define an identity is:

```elixir
identity <name_of_the_identity>, [<attribute_or_attributes_which_are_unique>]
```

You can find more information on identities via these links:

*   Identites in Ash Guides – [https://hexdocs.pm/ash/identities.html](https://hexdocs.pm/ash/identities.html#content)
*   DSL: Ash.Resource.Dsl – identities – [https://hexdocs.pm/ash/dsl-ash-resource.html#identities](https://hexdocs.pm/ash/dsl-ash-resource.html#identities)

## Custom Statements

If we are not able to fully represent tables from our database inside Ash Resources with the four sections `postgres`, `attributes`, `relationships` and `identities` that we've seen:

*   we can continue to read the docs and / or ask questions to the community, because Ash allow to describe many things in a clean way
*   we can also use a special trick: `custom_statements`, which is a sub-section of the `postgres` section

`custom_statements` are described [here](https://hexdocs.pm/ash_postgres/dsl-ashpostgres-datalayer.html#postgres-custom_statements) in the doc.

And here is an example of how we used them inside one of our Resource Description:

```elixir
 ### Sample from our Users Resource

    postgres do
    table "users"
    repo Prepair.Repo

    custom_statements do
      statement :users_id_fkey do
        up "ALTER TABLE ONLY public.users
            ADD CONSTRAINT users_id_fkey FOREIGN KEY (id)
            REFERENCES public.profiles(id)
            ON DELETE CASCADE
            DEFERRABLE INITIALLY DEFERRED;"
        down "DROP CONSTRAINT users_id_fkey"
      end

      statement :create_citext_extension do
        up "CREATE EXTENSION IF NOT EXISTS citext;"
        down "DROP EXTENSION IF EXISTS citext;"
      end

      statement :email_type do
        up "ALTER TABLE ONLY public.users
            ALTER COLUMN email
            SET DATA TYPE CITEXT;"
        down "ALTER TABLE ONLY public.users
            ALTER COLUMN email
            SET DATA TYPE TEXT;"
      end

      statement :role_type do
        up "ALTER TABLE ONLY public.users
            ALTER COLUMN role
            SET DATA TYPE VARCHAR(15);"
        down "ALTER TABLE ONLY public.users
            ALTER COLUMN role
            SET DATA TYPE VARCHAR;"
      end
    end
  end
```

These `custom_statements` can really be useful when it comes to exactly reproduce what's already in our database tables, because sometimes we can have slightly differences between our existing database, and what's generated from our Ash Resources. As it can be annoying to reproduce some little details, we can sometimes go faster with brut statements in the postgresql language.

Read our next article: **[Migrate Ecto Schemas into Ash Resources (3/3)](/fr/articles/migrate-ecto-schemas-into-ash-resources-3/)**
