---
title: Why Ash?
date: 2024-05-31T00:01:00
draft: false
type: articles
category: technical
tags:
- elixir
- ash
slug: why-ash
url: /fr/articles/why-ash
summary: Article technique non traduit en français. We explain our thoughts on why we decided to migrate from Phoenix to Ash for our application backend coded in Elixir.
---
Article technique non traduit en français.

(p)repair is a project to help people reduce their consumption of products. Firstly, we bet on building a mobile application. You can read more in [the project's manifesto](/fr/manifeste).

This article is part of the [Migration to Ash series](/fr/articles/migration-to-ash-series). Click for the summary, or just pick what you want here!

---

![Ash Logo](/images/articles/elixir/migration-to-ash-series/why-ash/ash-logo-side.svg)

For more context, read our previous article: **[Migration to Ash series](http://localhost:1313/fr/articles/migration-to-ash-series/)**

At one point, we needed to stabilize our API.

We are currently using [FlutterFlow](https://flutterflow.io/) as a no-code tool (which uses [Dart](https://dart.dev/) and the [Flutter](https://flutter.dev/) framework under the hood) for our frontend development. We have made this choice so we can iterate faster on the graphical interface, in prevision of the feedback of our first users.

Our API is the bridge between our homemade backend, using [Elixir](https://elixir-lang.org/) with the [Phoenix](https://www.phoenixframework.org/) framework, and our frontend, using a no-code tool.

FlutterFlow is mostly designed to use [Firebase](https://firebase.google.com/) as an online database, but we don’t use it. We prefer to remain more flexible at this step, and to don’t rely on a proprietary tool for such a critical part of our app. It could also lead to unpredicted costs in the future. We prefer to use [PostgreSQL](https://www.postgresql.org/).

However, we chose FlutterFlow as our Frontend no-code tool because it also supports the use of external APIs (only REST APIs for the moment). We can add API calls to our own server and application. API calls can be added manually, but it is painful. You can also import them through an [OpenAPI](https://swagger.io/resources/open-api/) file (also known as swagger file), following the OpenAPI spec 3.0 at least.

We previously redacted an OpenAPI file by hand for our project to test the integration on FlutterFlow. It works fine, but it is a pain to write it.

We had 2 goals to achieve:

*   coding a relatively stable API, to avoid the need of often changing the calls in the Frontend
*   using a tool capable of generating a swagger file for our API, directly based on our backend code

To make our API stable, we was wondering how to design it the best way as possible. Because we are at the begining of our project, it is hard to imagine which resources managed by the backend we will maybe need in a few weeks or months, through our API. We needed something flexible for the short and medium term, while remaining stable. Coding a GraphQL API would probably have been a good choice, but remember, FlutterFlow, our no-code tool for the frontend, currently don’t support this natively. We prefer to avoid tricks on FlutterFlow for such an important part of our application, so we stay on a REST API for the moment. Our researches drove us to the [JSON:API](https://jsonapi.org/) specification.

![JSON:API Logo](/images/articles/elixir/migration-to-ash-series/why-ash/jsonapi.png)

The JSON:API specification is a good spec, according to experienced people, so we will rely on it confidently. However, a good spec does not mean it is a pleasure to implement. Then, we had new researches on which tool could help us to implement the JSON:API specification within our Phoenix application.

Our researches led us to 2 complementary tools:

*   [JSONAPI Elixir](https://hexdocs.pm/jsonapi/readme.html) to encode our Ecto Schemas into  JSON:API documents, handling the last update (v1.1) of the relative specification
*   [Open API Spex](https://hexdocs.pm/open_api_spex/readme.html#content) to generate our OpenAPI file, handling the v3 of the relative specification

With all that said, we still needed to integrate two new tools to our project, to add code on each of our controllers, to update our tests and so on. There was work ahead.

In parallel, we also had a look at [Ash](https://ash-hq.org/), and thought it could be nice to think deeper on it in the future. But while [asking](https://elixirforum.com/t/p-repair-project-json-api-specification-integration/63116) the Elixir community which tool it would advice to implement JSON:API in a Phoenix app, I had an unexpected answer, from Zach Daniel, the creator of Ash framework for Elixir. Ash users can use [AshJsonApi](https://hexdocs.pm/ash_json_api/readme.html), and it looks like a breathe to support the spec with this tool. It can generate JSON:API compliant Schemas, directly from your [Resources](https://hexdocs.pm/ash/Ash.Resource.html), without writing new stuff on your controllers. This is the philosophy of Ash: you describe your Resources (more or less the equivalent of an Ecto Schema in which you can include other descriptions, like actions for functions, etc…), and the Ash framework will generate code for you from these descriptions, such as handling JSON:API specification for your Resources APIs if you want.

But implementing the Ash logic to our application is more work than just implementing JSON:API with 2 new dependencies that already do very good stuff as well. Why did we finally go to use Ash?

As explained above, Ash is about defining Resources to then have access to many interesting hands-on features that a lot of people need for their apps: it does not only support JSON:API, but also GraphQL, so it is an advancement for the future if we want to use other API system. This could sounds like a premature optimization choice, but wait… We just went through the authorization part just before we had to stabilize our API, and it was also a pain to do, even for a still small application, there were a lot of repetition in our code. This is the kind of feature which needs repetition over many possible calls. And it will probably have many changes on our authorization policy in the near future if we want more granularity on the procedure.

We realize it is already hard to have a clean view on everything, even with a still small application as I wrote, and in parallel, code reviews start to become a bottleneck in our very small organization. What about Ash? Ash is build with many hands-on extensions, and all this stuff natively supports JSON:API as we've seen. It also supports GraphQL, Authorization, Authentication, proposes an Admin interface ✅, and still other features. But most of all, it brings clarity to the code, thanks to its bigger abstraction which is possible due to a powerful machinery under the hood.

Thinking about that, I’m not sure if I would have pursue the experiment without the incredible help I got from the Ash team and community during my first steps onboard 🧡, just because alone I’m still a noob.

I arrive as a new user for the v3, and what I can say is that it seems like a clean and already mature framework. I’ve had very clear answers from very busy people, and it touched my heart. I also seen the official documentation really enhanced in only one month! There are still a few bugs sometimes popping when trying some custom things, but the team is so reactive that you have the impression it’s a support you paid for! On my experience, all things I reported have been corrected in the day, not to say in hours.

Ash team members are thinking faster than I think 🧠, and that’s why I’m confident using it now, as I was already confident using Elixir and Phoenix! It’s just a new crazy abstraction layer on the top of an already incredible language and libraries!

Let’s have a try!

In our next post, we will talk of the strategy we adopted to migrate our Phoenix project to the Ash framework, with code snippets.

Read our next article: **[What strategy to migrate from Phoenix to Ash?](/fr/articles/what-strategy-to-migrate-from-phoenix-to-ash/)**

---
Guillaume, from the (p)repair team
