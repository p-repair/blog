---
title: Preparation for the migration from Phoenix to Ash
date: 2024-05-31T00:04:00
draft: false
type: articles
category: technical
tags:
- elixir
- ash
url: /fr/articles/prepare-the-phoenix-to-ash-migration
summary: Article technique non traduit en français. We explain how we keep our application code clean and testable during all the migration process.
---
Article technique non traduit en français.

(p)repair is a project to help people reduce their consumption of products. Firstly, we bet on building a mobile application. You can read more in [the project's manifesto](/fr/manifeste).

This article is part of the [Migration to Ash series](/fr/articles/migration-to-ash-series). Click for the summary, or just pick what you want here!

---

For more context, read our previous article: **[Generalities on the migration to Ash](/fr/articles/generalities-on-the-migration-to-ash/)**

Because we don’t want our development app code to be in a broken state for an unknown amount of time, we will write our Ash Resources in parallel of our Ecto Schemas. That way, we will not break anything, and all tests should pass at each step of the migration.

Maybe we verify if everything is fine before by running the commodity `mix test`.

It’s all green, we can go further.

### Legacy Contexts

We create a folder named `legacy_contexts`, at the project level.

Our project name is (p)repair, written prepair in file names and Prepair in module names.

We create our new folder within this path: `lib/prepair/legacy_contexts`.

Now, we can put all our Phoenix Context files inside that new folder. We do the same for all our folders naming after our Context files and containing Ecto Schema files.

For instance, we have the following contexts: `accounts.ex`, `auth.ex`, `newsletter.ex`, `notifications.ex`, `products.ex`, `profiles.ex`. We move them. And we have folders: `products` containing `category.ex`, `manufacturer.ex`, `product.ex`, `part.ex`. All are representing Ecto Schemas. So we move all folders which regroups our actual Ecto Schemas as well, inside our new `legacy_context`.

Now we should have paths like that:

`lib/prepair/legacy_contexts/products.ex`

`lib/prepair/legacy_contexts/products/category.ex`
`lib/prepair/legacy_contexts/products/manufacturer.ex`
`lib/prepair/legacy_contexts/products/part.ex`
`lib/prepair/legacy_contexts/products/product.ex`

And so on…

We don’t need to move files that are not Phoenix Contexts, and we don’t need to move folders that are not containing the Ecto Schemas used in these Phoenix Contexts.

Now, we can do massive “search and replace” for each Phoenix Context we've moved. We search and replace in all our project, including test files.
For instance for our contexts, it goes like:

`Prepair.Accounts` → `Prepair.LegacyContexts.Accounts`
`Prepair.Auth` → `Prepair.LegacyContexts.Auth`
`Prepair.Newsletter` → `Prepair.LegacyContexts.Newsletter`
`Prepair.Notifications` → `Prepair.LegacyContexts.Notifications`
`Prepair.Products` → `Prepair.LegacyContexts.Products`
`Prepair.Profiles` → `Prepair.LegacyContexts.Profiles`

Now we run all our tests again… and everything should be green!

Good stuff, we prepared something nice.

### Ash Domains

We just create another folder named `ash_domains`, within this path: `lib/prepair/ash_domain`.

At the end of the day, our folder/files tree, from the root of our project, looks like that:

```
lib/
├─ prepair/					### project main directory
│  ├─ ash_domains/
│  │  ├─ accounts.ex		### Phoenix context
│  │  ├─ accounts/
│  │  │  ├─ user.ex			### Ecto Schema
│  │  │  ├─ user_token.ex	### Ecto Schema
│  │  │  ├─ …
│  │  ├─ products.ex		### Phoenix context
│  │  ├─ products
│  │  │  ├─ category.ex		### Ecto Schema
│  │  │  ├─ manufacturer.ex	### Ecto Schema
│  │  │  ├─ product.ex		### Ecto Schema
│  │  │  ├─ …
│  ├─ legacy_contexts/
│  │  ├─ accounts.ex		### Ash Domain
│  │  ├─ accounts/
│  │  │  ├─ user.ex			### Ash Resource
│  │  │  ├─ user_token.ex	### Ash Resource
│  │  │  ├─ …
│  │  ├─ products.ex		### Ash Domain
│  │  ├─ products
│  │  │  ├─ category.ex		### Ash Resource
│  │  │  ├─ manufacturer.ex	### Ash Resource
│  │  │  ├─ product.ex		### Ash Resource
│  │  │  ├─ …
│  ├─ application.ex		### nothing to do with this file
│  ├─ mailer.ex				### nothing to do with this file
│  ├─ repo.ex				### nothing to do with this file
│  ├─ …
├─ prepair_web/				### nothing to do inside this folder
├─ prepair_web.ex			### nothing to do with this file
├─ …
```

We are in a really good shape with that, trust me!

It worth a commit 😃

Read our next article: **[Migrate Ecto Schemas into Ash Resources (1/3)](/fr/articles/migrate-ecto-schemas-into-ash-resources-1/)**

---
Guillaume, from the (p)repair team
