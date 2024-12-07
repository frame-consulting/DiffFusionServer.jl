```@meta
CurrentModule = DiffFusionServer
```

# DiffFusionServer

Documentation for [DiffFusionServer](https://github.com/frame-consulting/DiffFusionServer.jl).

## Getting Started

In this section, we document the usage of `DiffFusionServer` via Julia. Alternatively, you can use `DiffFusionServer` via [Docker](https://en.wikipedia.org/wiki/Docker_(software)) without the need to install Julia.

The `DiffFusionServer` package uses `HTTP` and `Sockets` packages. These packages need to be added to the current project.

```
using Pkg
Pkg.add(url="https://github.com/frame-consulting/DiffFusionServer.jl")
Pkg.add("HTTP")
Pkg.add("Sockets")
```

Start a HTTP server.

```
using DiffFusionServer
using HTTP
using Sockets

router = DiffFusionServer.router().router
server = HTTP.serve!(router, Sockets.localhost, 2024)
```

Now you can visit the end point [localhost:2024](http://localhost:2024/api/v1/info) with your browser. This should display an info text of the API.

Alternatively, you can query the server via `HTTP` in Julia.

```
resp = HTTP.get("http://localhost/api/v1/info")
display(resp)
```

Finally, you can close the server via

```
close(server)
```

## Use Docker to Run the Server

A convenient way to run the `DiffFusionServer` is by using [Docker](https://en.wikipedia.org/wiki/Docker_(software)). A Docker image can be build locally or obtained from Docker Hub.

### Build Docker Image

Download or clone the `DiffFusionServer` source code and go to the [`docker` folder](https://github.com/frame-consulting/DiffFusionServer.jl/tree/main/docker).

The image can be build via

```
docker build --pull --rm -t diff-fusion-server:latest .
```

A container can be started from the built image via

    docker run --rm -it -p 2024:2024 diff-fusion-server:latest --port 2024

The server is listening on port 2024. If you can access the [info page](http://localhost:2024/api/v1/info) via browser then everything is set up.

### Pull Docker Image

Alternatively, you can pull a pre-build Docker image via

```
docker pull sschlenkrich/diff-fusion-server:latest
```

A container can be started from the pulled image via

    docker run --rm -it -p 2024:2024 sschlenkrich/diff-fusion-server:latest --port 2024

The server is listening on port 2024. If you can access the [info page](http://localhost:2024/api/v1/info) via browser then everything is set up.

## API Reference

This is a summary of the API to serve DiffFusion functionality via HTTP.

The API implements an object repository. Individual objects are accessible
via their 'alias' key.

Endpoints:

GET: [api_path]/[version]/info

- Return this info message.

GET: [api_path]/[version]/aliases

- Return the list of aliases in object repository.

POST: [api_path]/[version]/ops

- This method implements the main API logic:
  - Load request body into OrderedDict 'd'.
  - Retrieve 'alias' field from  request header.
  - Retrieve operation field 'op' from request header.
  - Process OrderedDict 'd' according to operation 'op'.
  - Store resulting object in object repository with key 'alias'.

- Operations 'op' are
  - 'COPY': copy body as OrderedDict to repository,
  - 'BUILD': de-serialise object and store in repository

POST: [api_path]/[version]/bulk

- This method implements the POST method for a list of object.
  - Request body contains a list of two-element lists.
  - Each two-element list contains the object 'alias' and the
    dictionary specifying the object creation.
  - Object creation follows the method for single-object POST
    method.

GET: [api_path]/[version]/ops

- Retrieve 'alias' field from  request header, serialise object from
  repository and return via body.

GET: [api_path]/[version]/bulk

- This method implements the GET method for a list of objects.
  - Request body contains a list of 'alias' keys.
  - Response body contains a list of serialised objects.

DELETE: [api_path]/[version]/ops/

- Retrieve 'alias' field from  request header and delete the object
  with given alias.

## Using `DiffFusion.jl` via API

The usage of the API is illustrated by Python and Julia notebooks in the [`examples` folder](https://github.com/frame-consulting/DiffFusionServer.jl/tree/main/examples).

The notebooks can be run via [![Binder](https://mybinder.org/badge_logo.svg)](https://mybinder.org/v2/gh/frame-consulting/DiffFusionServer.jl/v0.0.7?labpath=examples) or locally.

Additional examples are documented via the test suite.
