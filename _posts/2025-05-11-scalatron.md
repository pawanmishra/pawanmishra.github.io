---
layout: post
title: 
tags: [LLM, AI, Azure, OpenAI, Scala, RAG]
excerpt: Step-by-step guide on how I leveraged LLM and RAG to implement a bot in Scala.
---

### What is Scalatron?
---

[Scalatron](https://scalatron.github.io/pages/gettingstarted.html) is an educational resource for groups of programmers that want to learn more about the Scala programming language or want to hone their Scala programming skills. It is based on Scalatron BotWar, a competitive multi-player programming game in which coders pit bot programs (written in Scala) against each other. It is a free, open-source programming game in which bots, written in Scala, compete in a virtual arena for energy and survival.

{% include figure image_path="/assets/images/scalatron_arena.png" alt="Scalatron Arena" caption="Scaratron Arena" %}

For this excercise, I forked and cloned the repo locally. Once cloned, running `sbt dist`, created the dist package that contained the Scalatron jar and other directories wherein we can publish our own bots or see sample bots.

{% include figure image_path="/assets/images/scalatron_dist.png" alt="Scalatron Distribution" caption="Scalatron Distribution" %}

Start the Scalatron server by running `java -jar bin/Scalatron.jar`. This will spin-up the arena and also the web-ui(_localhost:8080_), wherein we can implement our own bot in Scala. 

{% include figure image_path="/assets/images/scalatron_webui.png" alt="Scalatron WebUI" caption="Scalatron WebUI" %}

From the web-ui, we can implement our bot, run it in a sandbox environment, or publish it to the tournament. Details of how Scalatron webserver picks up bots and runs in the arena and outlined in details in the site documentation.

In the subsequent section of this post, I will demonstrate, how I used LLM and RAG to implement the bot in Scala. It was pretty cool to see the bot in action in arena and to have it all implemented via an LLM, made it even more impressive.

### LLM Setup
---

I won't go into much details on this topic. Essentially, I used Azure OpenAI service, for hosting an LLM model and corresponding text embedding model. We can deploy llm models in [Azure Foundry](ai.azure.com). We can interact with the models, from within the foundry itself or use the API endpoints and the secret key to programatically access them via REST API endpoints. For this excercise, I deployed, **gpt-4.1** and **text-embedding-3-small** models in foundry. 

{% include figure image_path="/assets/images/foundry_models.png" alt="LLM Model" caption="LLM Model" %}

* **gpt-4.1** is the llm chat model which will be responsible for generating the output text/token.
* **text-embedding-3-small** is the embedding model. Embedding model is needed to translate our query and the knowledge base into vector representation that the llm can understand. 

### What is RAG?
---

**RAG** stands for _Retrieval-Augmented Generation_. RAG is an approach that combines traditional language generation models (like GPT or LLMs) with information retrieval systems.
When a user asks a question, the system first retrieves relevant documents or passages from a large external **_knowledge base_**.
The retrieved information is then provided as additional context to the language model, which uses it to generate more accurate and up-to-date responses.

**_knowledge base_** is the key here. We will see in the subsequent section, how to construct a knowledge base and use it with the deployed llm models, to get response that are geared towards the problem we are trying to solve i.e. implement a bot. 

### What is RagFlow?
---

[RagFlow](https://github.com/infiniflow/ragflow?tab=readme-ov-file#-what-is-ragflow) is an open-source RAG(Retrieval-Augmented Generation) engine based on deep document understanding. We can use their demo [site](https://demo.ragflow.io/) to build our sample RAG based application. 

In [RagFlow](https://github.com/infiniflow/ragflow?tab=readme-ov-file#-what-is-ragflow), we can choose from multiple llm providers, and conviniently build our chat or agent based systems. 

{% include figure image_path="/assets/images/ragflow_llm_providers.png" alt="RagFlow LLM Providers" caption="RagFlow LLM Providers" %}

To add a model, select the provider(in my case it was Azure OpenAI). In the pop-up window, provide details about your models - model name, api endpoint, secret key, type of model - chat or embedding, etc.

{% include figure image_path="/assets/images/add_model.png" alt="Adding Model" caption="Adding Model" %}

> **Note**: In a RAG based system, you need both i.e. the chat llm model as well as the text embedding model. Which is why, I had to deploy _gpt-4.1_ and _text-embedding-3-small_ embedding model.

We can now move on to the final and the crux of this post section i.e. leveraging RagFlow and the deploymed models in Azure, for implementing our bot.

### Bot Implementation
---

It is highly likely that if we ask our llm chat model(gpt-4.1) a Scalatron botwar specific question, it might just hallucinate and give a wrong answer or say I don't know. For e.g. when asked - "What is the name of the poisonous immobile plant in Scalatron botwar game?", llm reponse is - "The answer you are looking for is not found in the knowledge base!". The correct answer is Toxifera.

{% include figure image_path="/assets/images/llm_doesnt_know.png" alt="LLM Doesn't Know" caption="LLM Doesn't Know" %}

This is where RAG and more specifically the RAG's _knowledge base_ comes into play. With RAG, when we ask a question, RAG first looks for relevant information in the associated knowledge base, extracts the relevent information and passes it on to the llm as query's context. LLM then uses the additional information available in the context to formulate its response. For e.g. if I ask the same question to an RAG based llm, whose knowledge base is made up of Scalatron specific information, then I get the correct response.

{% include figure image_path="/assets/images/llm_knows.png" alt="LLM Knows" caption="LLM Knows" %}