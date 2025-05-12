---
layout: post
title: Implement a bot using LLM and RAG
tags: [LLM, AI, Azure, OpenAI, Scala, RAG]
excerpt: Step-by-step guide on how I leveraged LLM and RAG to implement a bot in Scala.
---
{% include base_path %}
{% include toc %}

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

Let's look into how to build our RAG's knowledgebase.

#### RAG Knowledge Base
---

In [RagFlow](https://github.com/infiniflow/ragflow?tab=readme-ov-file#-what-is-ragflow), we can create a _Knowledge Base_ by uploading documents. Documents that contain information related to the problem we are trying to solve. In our case, Scalatron repo includes multiple documents that explain the rules of the game, protocol, has sample implementations, etc. For this excercise, I decided to include the following documents - 

* [Scalatron Tutorial](https://github.com/scalatron/scalatron/blob/master/Scalatron/doc/markdown/Scalatron%20Tutorial.md)
* [Scalatron Protocol](https://github.com/scalatron/scalatron/blob/master/Scalatron/doc/markdown/Scalatron%20Protocol.md)
* [Scalatron Rules](https://github.com/scalatron/scalatron/blob/master/Scalatron/doc/markdown/Scalatron%20Game%20Rules.md)
* [Complex Bot Implementation](https://github.com/scalatron/scalatron/blob/master/Scalatron/samples/Example%20Bot%2001%20-%20Reference/src/Bot.scala)

{% include figure image_path="/assets/images/rag_knowledgebase.png" alt="RAG Knowledgebase" caption="RAG Knowledgebase" %}

Above files are small markdown documents. To construct the knowledge base, RAG framework has to parse and chunk the documents and store the information in a vector store. Once the knowledge base was ready, I started a chat session in [RagFlow](https://github.com/infiniflow/ragflow?tab=readme-ov-file#-what-is-ragflow), instructed it to use the above knowledge base and started asking Scalatron specific questions. 

#### Moment of truth
---

I was really impressed, how much better the llm responses were once RAG's knowledge base came into picture. It was as if, llm knew in & out of this game. Every response was to-the-point and accurate. Lets see some examples. To get to the final working model, I had to iterate over a couple of times to get the llm to understand what bot strategry I had in mind. 

* **Question** - Asking LLM to list the main entities of the Scalatron bot game.
{% include figure image_path="/assets/images/list_scalatron_entities.png" alt="Scalatron Entities" caption="Scalatron Entities" %}

As we can see, in the above image, llm response is also annotated with the knowledge base article.

* **Question** - does the Scalatron bot war game tells you about the size of the arena i.e. X, Y?
{% include figure image_path="/assets/images/arena_size.png" alt="Scalatron Arena Size" caption="Scalatron Arena Size" %}

Time for some coding related question answers.

* **Question** - we need a function inside cell class that wraps up if the bot ends up on the edge of the arena. Wrap it back on the other side of the arena.
{% include figure image_path="/assets/images/wrap_cell.png" alt="Scalatron Wrap cell" caption="Scalatron Wrap cell" %}

* **Question** - summarize the Scalatron input protocol? How to correctly parse the input and what the return response should look like?
{% include figure image_path="/assets/images/scalatron_input_response.png" alt="Scalatron Input Response" caption="Scalatron Input Response" %}

After this I asked few more questions related to input, about the characters, etc. 

Finally, I asked llm to generate code for my bot. I had to present my bot's strategy as a question. So here it is - _**Give master bot center location, it's view in terms of the View class, write code that finds nearby Fluppet or Zugar(whichever is nearby) and move the master bot in that direction. If no food available then move randomly in any direction, while avoiding toxifera and snorg. Avoid walls as well. If the bot gets stuck against the wall. Update the code to handle wall as well?**_

**Code** - 

```scala
// this is the source code for your bot - have fun!

import scala.util.Random

class ControlFunctionFactory {
    def create = new Bot().respond _
}

class Bot {
    
    // All possible move directions (excluding staying put):
    val directions8 =
        Seq(XY(-1,-1), XY(0,-1), XY(1,-1),
            XY(-1,0),            XY(1,0),
            XY(-1,1), XY(0,1), XY(1,1)).filterNot(_ == XY(0,0))
    
    def isSafe(cellContent: Char): Boolean =
        cellContent != 'p' && cellContent != 'b' && cellContent != 'W'

    def safeDirections(view: View): Seq[XY] =
        directions8.filter(dir => isSafe(view(dir)))
    
    def respond(input: String) = {
        val paramMapping = parseInput(input)
        val opCode = paramMapping._1
        val result = opCode match {
            case "React" => {
                val viewString = paramMapping._2("view")
                val view = View(viewString)
                val food = findNearestFood(view)
                food match {
                 case Some(targetDelta) =>
                   // Move one step towards targetDelta:
                   val moveDelta =
                     XY(targetDelta.x.signum, targetDelta.y.signum)
                     
                    // Only move if that direction is safe!
                   if(isSafe(view(moveDelta))) {
                     s"Move(direction=${moveDelta})" // e.g., Move(direction=1:-1)
                   } else {
                     // If direct path is blocked by hazard or wall,
                     // pick a random safe direction instead.
                     val safeDirs = safeDirections(view)
                     if(safeDirs.nonEmpty){
                       val chosenDir = Random.shuffle(safeDirs).head
                       s"Move(direction=${chosenDir})"
                     } else {
                       "Status(text=No safe moves)"
                     }
                   }    
                
                   //s"Move(direction=${moveDelta})" // e.g., Move(direction=1:-1)
                
                 case None =>
                   // No food found; pick a random safe direction:
                   val safeDirs = safeDirections(view)
                   
                   if(safeDirs.nonEmpty){
                     val chosenDir = Random.shuffle(safeDirs).head
                     s"Move(direction=${chosenDir})"
                   } else {
                     "Status(text=No safe moves)"
                   }
                
                }
            }
            case _ => {
                val chosenDir = Random.shuffle(directions8).head
                s"Move(direction=${chosenDir})"
            }
        }
        result
        //"Status(text=pawan)"
    }
    
    def parseInput(input: String): (String, Map[String, String]) = {
        println(input)
        val tokens = input.split('(') // Array("React", "generation=0,time=100,...")
        val opcode = tokens(0)
        val paramsString = tokens(1).dropRight(1) // "generation=0,time=100,view=...,energy=100"
        val paramsArray = paramsString.split(',')
        val paramMap = paramsArray.map(_.split('=')).map(a => (a(0), a(1))).toMap
        (opcode, paramMap)
    }
    
    def findNearestFood(view: View): Option[XY] = {
      val foodChars = Set('B', 'P')
      
      // Generate all possible relative positions within view range except center (0,0)
      val range = -(view.size/2) to (view.size/2)
      
      val foodPositions =
        for {
          dx <- range; dy <- range if !(dx == 0 && dy == 0)
          pos = XY(dx, dy)
          c   = view(pos)
          if foodChars.contains(c)
        } yield pos
    
       // Find nearest by Manhattan distance:
       foodPositions.sortBy(_.length).headOption
    }
}

case class View(cells: String) {
  val size = math.sqrt(cells.length).toInt
  val center = XY(size / 2, size / 2)

  // Convert absolute position (from top-left) to index in string
  def indexFromAbsPos(absPos: XY): Int = absPos.x + absPos.y * size

  // Convert relative position (from bot's perspective) to absolute position
  def absPosFromRelPos(relPos: XY): XY = relPos + center

  // Access cell at absolute position
  def cellAtAbsPos(absPos: XY): Char = cells.charAt(indexFromAbsPos(absPos))

  // Access cell at relative position (relative to bot)
  def cellAtRelPos(relPos: XY): Char = {
    val abs = absPosFromRelPos(relPos)
    if (abs.x >=0 && abs.x < size && abs.y >=0 && abs.y < size)
      cells.charAt(indexFromAbsPos(abs))
    else '?'
  }

  // Overload apply for convenient access with relative coordinates
  def apply(relXY: XY): Char = cellAtRelPos(relXY)
}

case class XY(x: Int, y: Int) {
  def +(other: XY): XY = XY(x + other.x, y + other.y)
  def length: Int = math.abs(x) + math.abs(y) // Manhattan distance
  override def toString: String = s"$x:$y"
}
```

I can assure you that almost 95% of the above code was generated by the llm. I had to tweak it a bit to make it Scalatron compatible. And to fix some scala compilation issues. But The output was simply amazing. To see the bot in action made this excercise totally worth the time and effort. Here is the bot in action - 

{% include figure image_path="/assets/images/scalatron_bot.gif" alt="Scalatron Bot" caption="Scalatron Bot" %}

