---
title: 'Migration to Ash series'
date: 2024-05-31T00:00:00
draft: false
type: series
category: technical
tags:
- elixir
- ash
slug: why-ash
url: /fr/articles/migration-to-ash-series
summary: Article technique non traduit en français. We wrote a series of technical articles dedicated to our migration on the Ash framework, for our application backend written in Elixir.
---
Article technique non traduit en français.

(p)repair is a project to help people reduce their consumption of products. Firstly, we bet on building a mobile application. You can read more in [the project's manifesto](/fr/manifeste).

---

We are currently building a mobile application. Our backend is coded with [Elixir](https://elixir-lang.org/) language. We went on the [Phoenix](https://www.phoenixframework.org/) framework for the power of its many hands-on features.

However, through time, we discovered another framework which awakens our interest for its philosophy: [Ash](https://ash-hq.org/).

Ash [website](https://ash-hq.org/) and many [documentation](https://hexdocs.pm/ash/get-started.html) are a very nice places to familiarize yourself with the concepts and features Ash provides.

This article series is also a good way to follow the path of our thoughts:
* we explain our decision to migrate from Phoenix to Ash
* we explore code differences from one to the other of these Elixir frameworks

Here is the current index of this article series. You can click on every title, this will redirect you to the linked article.


1. **[Why Ash?](/fr/articles/why-ash)**

    ➔ To understand the context of why we decided to migrate from Phoenix to Ash.

2. **[What strategy to migrate from Phoenix to Ash?](/fr/articles/what-strategy-to-migrate-from-phoenix-to-ash/)**

    ➔ The current plan of our strategy migration.

3. **[Generalities on the migration to Ash](/fr/articles/generalities-on-the-migration-to-ash/)**

    ➔ Details only a few steps to install Ash on our project.

4. **[Preparation for the migration from Phoenix to Ash](/fr/articles/prepare-the-phoenix-to-ash-migration/)**

    ➔ Explains how we keep our application code clean and testable during all the migration process.

5. **[Migrate Ecto Schemas into Ash Resources (1/3)](/fr/articles/migrate-ecto-schemas-into-ash-resources-1/)**

    ➔ For a general comprehension on how Ash works versus Phoenix works.

6. **[Migrate Ecto Schemas into Ash Resources (2/3)](/fr/articles/migrate-ecto-schemas-into-ash-resources-2/)**

    ➔ Code examples to migrate an Ecto Schema into an Ash Resource.

7. **[Migrate Ecto Schemas into Ash Resources (3/3)](/fr/articles/migrate-ecto-schemas-into-ash-resources-3/)**

    ➔ Why and how to compare the Ash generated migration with your previous database state.

More articles will probably be added in the future, to document the other steps of our migration.

Read our next article on this series: **[Why Ash?](/fr/articles/why-ash)**

---
Guillaume, from the (p)repair team
