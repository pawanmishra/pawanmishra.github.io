---
layout: post
title: LLM Using Azure OpenAI
tags: [LLM, AI, Azure]
excerpt: Step by step guide on how to configure Azure OpenAI service and use it for working with LLMs.
---

There are primarily two ways of interacting with LLM's. One via dedicated chat like interface and the other option is progrmatically via API. In this blog post, we are going to see, how we can use the Azure's OpenAI api endpoints for interacting with llm's hosted in Azure. 

At a high level, we will be going through the following steps -

* Deploy the [Azure OpenAI](https://azure.microsoft.com/en-us/products/ai-services/openai-service) service in Azure portal. This deploys the [Azure OpenAI](https://azure.microsoft.com/en-us/products/ai-services/openai-service) api endpoints and creates the secret key(s) needed for interacting with the service.
* Deploy model in Azure foundry. Once Azure OpenAI service is up and running, head to Azure foundry and deploy model of your choice.
* Finally, use Langchain's Azure OpenAI api for interacting with the model(deployed in Foundry) via the api endpoint.

### Deploy Azure OpenAI Service

To keep things simple, we are going to spin up the service directly in the portal. We are also going to opt for the most straightforward options like no networking related restrictions, etc. Below are the screenshots of the [Azure's OpenAI](https://azure.microsoft.com/en-us/products/ai-services/openai-service) service setup process. We first have to define a resource group and provide meanigful resource name, next make network related selections.

{% include figure image_path="/assets/images/openai_basics.png" alt="Azure OpenAI Resource Page" caption="Azure OpenAI Resource Page" %}

{% include figure image_path="/assets/images/openai_network.png" alt="Azure OpenAI Network Page" caption="Azure OpenAI Network Page" %}

{% include figure image_path="/assets/images/openai_create.png" alt="Azure OpenAI Create Page" caption="Azure OpenAI Create Page" %}

In just, three steps, we have successfully created the [Azure's OpenAI](https://azure.microsoft.com/en-us/products/ai-services/openai-service) resource. What this does is, it creates an api endpoint for us and also generates the API key that we need to provide when invoking the api.

{% include figure image_path="/assets/images/openai_resource.png" alt="Azure OpenAI Resource Page" caption="Azure OpenAI Resource Page" %}

Clicking on the endpoints link, will take us to the next page, wherein we can see the api and key details.

{% include figure image_path="/assets/images/openai_endpoints.png" alt="Azure OpenAI Endpoints Page" caption="Azure OpenAI Endpoints Page" %}

Make a note of the api endpoint and the keys(keep it safe and secure).

### Deploy Models in Foundry

After successfully deploying the [Azure OpenAI](https://azure.microsoft.com/en-us/products/ai-services/openai-service) service, next step we have to take is to deploy an llm model in [Azure Foundry](https://learn.microsoft.com/en-us/azure/ai-studio/what-is-ai-studio). In the Azure's OpenAI service page, click on the Foundry link. This will take you to the [Foundry](https://learn.microsoft.com/en-us/azure/ai-studio/what-is-ai-studio) portal.

{% include figure image_path="/assets/images/openai_foundry.png" alt="Azure OpenAI Foundry Page" caption="Azure OpenAI Foundry Page" %}

On this page, click on the "Create new deployment" link. This will pop-up another window wherein you can make the selection.

{% include figure image_path="/assets/images/openai_foundry_model.png" alt="Azure OpenAI Foundry Model Page" caption="Azure OpenAI Foundry Model Page" %}

Select model that you want and click on deploy. For this blog post, I have deployed the gpt-3.5-turbo model.

### Azure OpenAI via Langchain

[Langchain](https://python.langchain.com/docs/introduction/) is a well know framework that provides api's for interacting with well known llm providers. In the below example, I am going to use Langchain's AzureOpenAI api endpoints for interacting with the Azure's OpenAI service we have deployed in the previous steps.

Lets create a blank directory in our local machine. Once inside it, use the below command to create a virtual environment -

> python3 -m venv pm

Once created, activate the virtual environment by executing the following command -

> source pm/bin/activate

Next, lets use pip3 to install dependencies required by our python script. Execute the below command -

> pip3 install python-dotenv openai langchain-openai langchain-community

python-dotenv package is for loading **.env** files.

Next, create a **.env** file in the directory and copy paste in it the the Azure OpenAI bseapi and the secret key. 

> Important: having the key in the env file is fine, as long as you are using it for testing. Don't commit and checkin the env file and push it into remote repos. It's best practice to fetch this key from some sort of vault.

```
AZURE_OPENAI_ENDPOINT=<api_endpoint_copied_from_the_azure_openai_endpoints_page>
AZURE_OPENAI_API_VERSION=2024-02-15-preview
AZURE_OPENAI_API_TYPE=azure
AZURE_OPENAI_API_KEY=<api_key_copied_from_the_azure_openai_endpoints_page>
region=eastus
```

Finally, create a python script called **script.py** and paste the following code in it.

```script.py
import os
import openai
from dotenv import load_dotenv, find_dotenv
from langchain_openai import AzureChatOpenAI

load_dotenv(find_dotenv()) #1

OPENAI_API_KEY = os.getenv("AZURE_OPENAI_API_KEY")
OPENAI_API_TYPE = os.getenv("AZURE_OPENAI_API_TYPE")
OPENAI_API_BASE = os.getenv("AZURE_OPENAI_ENDPOINT")
OPENAI_API_VERSION = os.getenv("AZURE_OPENAI_API_VERSION")

llm = AzureChatOpenAI(                      #2
    azure_deployment="gpt-35-turbo",        #3
    api_version="2024-02-15-preview",  
    temperature=0.7,
    max_tokens=800,
    timeout=None,
    top_p=0.95,
    frequency_penalty=0,
    presence_penalty=0,
    stop=None
)

messages = [
    (
        "system",
        "You are a helpful assistant that translates English to French. Translate the user sentence.",
    ),
    ("human", "This is a beautiful world."),
]
ai_msg = llm.invoke(messages)
print(ai_msg.content)
``` 

Above is a basic hello world level example of working withan llm. 

`load_dotenv(find_dotenv())` automatically finds and loads the data from the **.env**. Next, we create an instance of the `AzureChatOpenAI` client. Passing to it are the model name and the other necessary parameters. Finally, we construct the message and invoke the api via `llm.invoke`. We want the llm to translate `This is a beautiful world` in French. Running the above script via `python3 script.py` returns **`C'est un monde magnifique.`**
