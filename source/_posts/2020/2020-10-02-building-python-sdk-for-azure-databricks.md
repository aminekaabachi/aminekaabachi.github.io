---
layout: post
title: Building a Python SDK for Azure Databricks
date: 2020-10-02 10:00:00+01:00
description: This article is about an open source Python SDK for Azure Databricks. It will present the  project. The progress of the current release  but also design choices and the overall dev process / tools.
image:
  url: /assets/images/posts/sdk-databricks/feature.png
  width: 1508
  height: 774
permalink: building-python-sdk-for-azure-databricks
tags:
  - databricks
  - azure
  - python
---

This article is about a new project I started to work on lately. Please welcome [Azure Databricks SDK Python](https://azure-databricks-sdk-python.readthedocs.io/en/latest/). As it’s shining through the name 🦄, It is a high-quality Python SDK for Azure Databricks REST API 2.0.

<div style="position:relative;padding-bottom:62.25%;">
  <img loading="lazy" style="max-width:100%; border: 0;position:absolute;top:0;left:0" sizes="(max-width: 1200px) 100vw, 684px" src="/assets/images/posts/sdk-databricks/feature.png" alt="">
</div>

This article will present the project, the current progress, release plan,  some design choices, and at final dev process/tools.

<!-- more -->
I spent several nights working and searching for best practices to implement this SDK. I am convinced that It will need more than my humble efforts to become stable and usable in production. Therefore, my friends, all contributions are welcome! Do not hesitate to reach to me if you want to contribute by any means (docs, code, testing, etc).

Motivation 
----------

I will start by my own use-cases: 

- ***Mix and match***: When working on a competitive field, you will have to cope with having new tools and platforms popping out from nowhere. I like to have simple means to mix my most-used tools with the brand-new ones. Using APIs to integrate directly is time-consuming, which leads in most cases to hacks and error-prone automation.

- ***Keeping evolving***: Usually, the ecosystem does not integrate the preview features. For example, Data Factory still does not include the docker options (DCS) when creating a cluster in the Databricks activity. Sometimes, you need to force the update. An SDK could be very useful to build custom connectors.

- ***Custom bricks***: You want to build on top of Azure Databricks: let's imagine You have a great idea that you must prototype as fast as you can, for a startup or a hackathon. If some of its blocks could be done by Azure Databricks, an SDK will help you do it in no time. You will be able to bundle everything in your app or package (et voilà !).

I think It's plenty to justify the need. Nonetheless, I am quite sure there should be additional use-cases. I'll be excited to hear yours in the comments (on medium).

Specs
-----

I want to create an SDK with he following features:

- Clear standard to access to APIs (e.g. through a client).
- Contains custom types for the API results and requests.
- Support for Personal Access token authentification.
- Support for Azure AD authentification.
- Support for the use of Azure AD service principals.
- Allows free-style API calls with a force mode (bypass types validation).
- Error handeling and proxy support.

In a nutshell, it should support all available authentification methods and manage operations on Azure Databricks through type objects. It should have simple methods to access results (no .get() hell) but also keep the possibility for free-style API calls.

By the way, I looked at other trials on doing this. Some projects use the underlying packages from `databricks-cli` which I think is a genuine idea. For the fun of it, I wanted to do it from scratch, but also because it should give more flexibility in the future.


Demo / Implementation Progress 
------------------------------

This part contains details about the current release, usage demo, and the release plan.

### Current release

Current release is v0.0.2. As of this version here is the implementation progress:

- ✔  Authentification
- ✔  Custom types (25%)
- ✔  API Wrappers (25%)
- ✔  Error handling (80%)
- ✗  Proxy support (0%)
- ✔  Documentation (20%)

The following API wrappers are now fully implemented and tested:

- ✔  Clusters
- ✔  Secrets
- ✔  Tokens

### Usage demo

Here is a demo from the [SDK Quickstart Guide](https://azure-databricks-sdk-python.readthedocs.io/en/latest/user/quickstart.html):

> Begin by importing the `clients.Client` class from SDK module.

```python
from azure_databricks_sdk_python import Client
```

> You can now instantiate a client object. You need to pass the databricks instance (format: adb-<XXX>.<X>.azuredatabricks.net) and your token:

```python
client = Client(databricks_instance=<instance>, personal_access_token=<token>)
```

> You can create a new cluster using the following:

```python
cluster = client.tokens.create(attributes)
```

> `attributes` are instance of `types.clusters.ClusterAttributes`. So before creating a cluster you need to create define its attributes. Here is an example:

```python
attributes = ClusterAttributes(cluster_name="my-cute-cluster", 
                                spark_version="7.2.x-scala2.12",
                                node_type_id="Standard_F4s", 
                                autoscale=autoscale)
```

> Now `create` will return an instance of `types.clusters.ClusterInfo`. You can access it's properties through dot chainin, for example:

```python
cluster.cluster_id
>>>  '0918-220215-atria616'
```

### Release plan

The release plan for the next versions (`v0.0.3` and `v0.0.4`) will be as follows.
I will be focusing on `v0.0.3`, hence contributors can start working on `v0.0.4` if they are interested.

- ***v0.0.3***: Jobs, Groups.
- ***v0.0.4***: DBFS, Libraries, Workspaces.

They should be released in few weeks from now. The goal is to reach a first stable version v0.1.0 this year.

Internals & Design Choices
--------------------------

These choices here should help gain time for change and extension. I think laziness is a good motive, although implicitly pejorative, it is the abstract for some of the software engineering principles (e.g. reuse).  To note that extension of the SDK is done through two operations: an API change or addition of an authentification method.

### Drafting

The fundamental idea of this SDK is to have a Client object as main interface. It encapsulates API wrappers: e.i. It means that you can call clusters API  through `client.clusters.create(...)`.

<div style="position:relative;margin:10% 0 0 0;padding-bottom:40.25%;">
  <img loading="lazy" style="max-width:100%; border: 0;position:absolute;top:0;left:0" sizes="(max-width: 768px) 100vw, 684px" src="/assets/images/posts/sdk-databricks/sdktarget.png" alt="">
</div>

<center ><u>Figure 1: Three-tier architecture class diagram.</u></center>

<br />

At first, I imagined a three-tier architecture:

- ***White layer***: The main interface that handles the configuration and abstracts the calls to the API wrappers (by aggregating them).
- ***Green layer***: The API wrappers. Also, the type packages that include models for requests and responses from different endpoints.
- ***Yellow layer***: Generic API helpers like functions that do HTTP get and post requests, and also HTTP error handlers.

To test this architecture, I asked two questions:

* *What do I need to change if I add a new authentification method ?* : In this case, I will need to modify the Client class and the API class. The change can lead (Murphy's law) to regression in the SDK. This constraint can be relaxed with a fair amount of tests. Still, It may lead (Murphy's law again) to breaking the <abbr title="Open-Closed Principle">OCP</abbr> once multiple versions accumulate because keeping consistency through versions with one class and stacking implementations is one of the worst practices in dev.

* *What do I need to change if I add a new API wrapper ?* : In this case, I need to modify the Client class too. The main issue here is that Client class is getting many responsibilities: configuration, the aggregation of API wrappers, etc. You can see that It breaks the  <abbr title="Single Responsibility Principle">SRP</abbr> this time (no Murphies needed).

Finally, It was time to for solutions: I tried my best. Still, much refactoring and evaluation are needed to improve the SDK quality. If you got ideas to improve the current solution or have a completely different way that can help in the long run, please get in touch.

### Designing
 
I like LEGO®. I also think that LEGO® makes good metamodels for programming. LEGO® is a master of <abbr title="Single Responsibility Principle">SRP</abbr> through its tiny blocks. Inspired, I tried to form a new solution by separating responsibilities in my layers.

<div style="position:relative;margin:10% 0 20% 0;padding-bottom:92%">
  <img loading="lazy" style="max-width:100%; border: 0;position:absolute;top:0;left:0" sizes="(max-width: 768px) 100vw, 684px" src="/assets/images/posts/sdk-databricks/sdkfull.png" alt="">
</div>

<center ><u>Figure 1: <s>Unscientific</s> multitier architecture class diagram.</u></center>

<br />

I started by introducing these changes:

- ***White layer***: The main interface now is just a Factory: i.e. It instantiates childs of BaseClient that now construct the purple layer.

- ***Purple layer***: It handles the configuration for each auth method. If I add a new auth method, the existing ones are not affected. The aggregation with  API wrappers is delegated (through composition) to a single responsibility class called Composer. 

- ***Green layer***: The green layer API wrappers all aggregate in a Composer class. It frees the purples to handle only configuration logic.

- ***Yellow layer***: The yellow layer is now divided into a Factory API class and separate classes that handle generic and specific HTTP operations based on the auth method.

As for changes, minimal additions are now needed for the usual extension use-case. It seems to be a good start for now.

### Implementing

Apart from abstract design choices, the one thing I hate the most in dealing with raw APIs is what I call ".get() hell". Typing, is a powerful concept. When dealing with APIs it helps a big deal. However, the challenge is the following. Azure Databricks API data structures are usually trees of basic types. You can find up to 3 or 4 layers deep. This makes the job of parsing input and output in order to return and accept custom type objects a challenging task.

Here are the two libs that made it very easy to solve this challenge:

- [`attrs`](https://www.attrs.org/en/stable/): package that will bring back the joy of writing classes by relieving you from the drudgery of implementing object protocols (aka dunder methods). This was useful mainly for Type Annotations. 

- [`cattrs`](https://github.com/Tinche/cattrs) is an open source Python library for structuring and unstructuring data. cattrs works best with attrs classes and the usual Python collections, but other kinds of classes are supported by manually registering converters.

Let's look at an example that uses attrs and cattrs:

```python

>>> from enum import unique, Enum
>>> from typing import List, Optional, Sequence, Union
>>> from cattr import structure, unstructure
>>> import attr
>>>
>>> @unique
... class CatBreed(Enum):
...     SIAMESE = "siamese"
...     MAINE_COON = "maine_coon"
...     SACRED_BIRMAN = "birman"
...
>>> @attr.s
... class Cat:
...     breed: CatBreed = attr.ib()
...     names: Sequence[str] = attr.ib()
...
>>> @attr.s
... class DogMicrochip:
...     chip_id = attr.ib()
...     time_chipped: float = attr.ib()
...
>>> @attr.s
... class Dog:
...     cuteness: int = attr.ib()
...     chip: Optional[DogMicrochip] = attr.ib()
...
```

Note that __init__ methods (and more) for the @attr.s are automatically generated. Now we can convert to and from these models using unstructure and structure functions.

```python

>>> p = unstructure([Dog(cuteness=1, chip=DogMicrochip(chip_id=1, time_chipped=10.0)),
...                  Cat(breed=CatBreed.MAINE_COON, names=('Fluffly', 'Fluffer'))])
...
>>> print(p)
[{'cuteness': 1, 'chip': {'chip_id': 1, 'time_chipped': 10.0}}, {'breed': 'maine_coon', 'names': ('Fluffly', 'Fluffer')}]
>>> print(structure(p, List[Union[Dog, Cat]]))
[Dog(cuteness=1, chip=DogMicrochip(chip_id=1, time_chipped=10.0)), Cat(breed=<CatBreed.MAINE_COON: 'maine_coon'>, names=['Fluffly', 'Fluffer'])]

```

As You can see, this helps to pass from low-level representation to structured data and vice versa. I used cattrs to handle input and responses. I also used attr to model all the types from the API and our implementation seems very clean compared to official APIs that struggle to implement it in a clean and readable way ([check this out](https://github.com/kubernetes-client/python/tree/master/kubernetes/client/models) and compare it [to this](https://github.com/aminekaabachi/azure-databricks-sdk-python/tree/master/azure_databricks_sdk_python/types)).


My Process / Tools
------------------

The CICD process for linting, testing, publishing the package use [Github actions](https://docs.github.com/en/free-pro-team@latest/actions).

### Developement 

Let's start with a preview of the building workflow:

```yml

name: Unit Tests
on:
  push:
    branches: [ master ]
    paths:
      - "azure_databricks_sdk_python/**.py"
      - "tests/**.py"
      - ".github/workflows/**.yml"
      - ".coveragerc"
      - "requirements.txt"
      - "requirements-tests.txt"

jobs:
  coverage:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v2

      - name: Set up Python
        uses: actions/setup-python@v2
        with:
          python-version: 3.8.2

      - name: Install dependencies
        run: |
          python -m pip install --upgrade pip
          pip install coveralls coverage
          if [ -f requirements.txt ]; then pip install -r requirements.txt; fi
          if [ -f requirements-test.txt ]; then pip install -r requirements-test.txt; fi
      - name: Run Test Suite
        env:
          DATABRICKS_INSTANCE: ${{ secrets.DATABRICKS_INSTANCE }}
          PERSONAL_ACCESS_TOKEN: ${{ secrets.PERSONAL_ACCESS_TOKEN }}
          DATABRICKS_INSTANCE_PREMIUM: ${{ secrets.DATABRICKS_INSTANCE_PREMIUM }}
          PERSONAL_ACCESS_TOKEN_PREMIUM: ${{ secrets.PERSONAL_ACCESS_TOKEN_PREMIUM }}
        run: |
          pytest --cov azure_databricks_sdk_python --junitxml=junit/test-results.xml tests/
      - name: Send Results to Coveralls
        env:
          DATABRICKS_INSTANCE: ${{ secrets.DATABRICKS_INSTANCE }}
          PERSONAL_ACCESS_TOKEN: ${{ secrets.PERSONAL_ACCESS_TOKEN }}
          DATABRICKS_INSTANCE_PREMIUM: ${{ secrets.DATABRICKS_INSTANCE_PREMIUM }}
          PERSONAL_ACCESS_TOKEN_PREMIUM: ${{ secrets.PERSONAL_ACCESS_TOKEN_PREMIUM }}
          COVERALLS_REPO_TOKEN: ${{ secrets.COVERALLS_REPO_TOKEN }}
        run: |
          coveralls

```

I used [pytest](https://docs.pytest.org/en/stable/contents.html) and [coveralls](https://coveralls.io/) for the two steps. Env variables for my Azure Databricks test workspaces are provided and the values are aggregated from [Github repo secrets](https://docs.github.com/en/free-pro-team@latest/actions/reference/encrypted-secrets).

I also included a workflow to automatically publish the package when a release is made:

```yml
name: Publish to PyPI

on:
  release:
    types: [created]

jobs:
  deploy:

    runs-on: ubuntu-latest

    steps:
    - uses: actions/checkout@v2
    - name: Set up Python
      uses: actions/setup-python@v2
      with:
        python-version: '3.x'
    - name: Install dependencies
      run: |
        python -m pip install --upgrade pip
        pip install setuptools wheel twine pbr
    - name: Build and publish
      env:
        TWINE_USERNAME: ${{ secrets.TWINE_USERNAME }}
        TWINE_PASSWORD: ${{ secrets.TWINE_PASSWORD }}
        TWINE_NON_INTERACTIVE: true 
      run: |
        python setup.py sdist bdist_wheel
        twine upload dist/*

```

It uses [twine](https://twine.readthedocs.io/en/latest/) to publish the package.

### Documentation

I used [sphinx](https://www.sphinx-doc.org/en/master/) with some extensions and [readthedocs.org](https://readthedocs.org/).

This screencast by [Mahdi Yusuf](https://realpython.com/team/myusuf/) will help you get started If you want to contribute to the docs:

<div style="text-align: center;">
<iframe width="100%" height="350" src="https://www.youtube-nocookie.com/embed/oJsUvBQyHBs?rel=0" frameborder="0" allow="autoplay; encrypted-media" allowfullscreen=""></iframe>
</div>

Resources
-------------------

Please let me know what you think and You can keep up with the project through:

- [Docs.](https://azure-databricks-sdk-python.readthedocs.io/en/latest/)
- [Github repository.](https://github.com/aminekaabachi/azure-databricks-sdk-python)
- [PyPi project.](https://pypi.org/project/azure-databricks-sdk-python/)
- [Coveralls.](https://coveralls.io/github/aminekaabachi/azure-databricks-sdk-python?branch=master)

