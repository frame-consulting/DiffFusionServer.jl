# DiffFusionServer

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://frame-consulting.github.io/DiffFusionServer.jl/stable/)

[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://frame-consulting.github.io/DiffFusionServer.jl/dev/)

[![Build Status](https://github.com/frame-consulting/DiffFusionServer.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/frame-consulting/DiffFusionServer.jl/actions/workflows/CI.yml?query=branch%3Amain)

[![Coverage](https://codecov.io/gh/frame-consulting/DiffFusionServer.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/frame-consulting/DiffFusionServer.jl)

[![Binder](https://mybinder.org/badge_logo.svg)](https://mybinder.org/v2/gh/frame-consulting/DiffFusionServer.jl/v0.0.2?labpath=examples)

The DiffFusionServer.jl package provides a REST API for the [DiffFusion.jl](https://github.com/frame-consulting/DiffFusion.jl) exposure simulation framework.

The server accepts HTTP requests with methods GET, POST, DELETE. The methods are used to query and modify an object repository.

The POST method is used to create objects via DiffFusion methods. Objects are labelled with an identifier (*alias*). Subsequent GET method requests retrieve the object. Requests with DELETE method allow deleting objects in the repository.

Details of requests are stored in the request header and the request body. The request body is interpreted as JSON format. Results from requests are stored in the response body. Results are also interpreted as JSON format.

## Getting Started

A convenient way to run the `DiffFusionServer` is by using [Docker](https://en.wikipedia.org/wiki/Docker_(software)). A Docker image can be build locally or obtained from Docker Hub.

### Build Docker Image

Download or clone the `DiffFusionServer` source code and go to the [`docker` folder](https://github.com/frame-consulting/DiffFusionServer.jl/tree/main/docker).

The image can be build via

```
docker build --pull --rm -t diff-fusion-server:latest .
```

### Pull Docker Image

Alternatively, you can pull a pre-build Docker image via

```
docker pull sschlenkrich/diff-fusion-server:latest
```

### Start Docker Container

Once the image is available, a container can be started via

    docker run --rm -it -p 2024:2024 diff-fusion-server:latest --port 2024

The server is listening on port 2024. If you can access the [info page](http://localhost:2024/api/v1/info) via browser then everything is set up.

## Using `DiffFusion.jl` via API

The usage of the API is illustrated by Python and Julia notebooks in the [`examples` folder](https://github.com/frame-consulting/DiffFusionServer.jl/tree/main/examples).

The notebooks can be run via [MyBinder.org](https://mybinder.org/) or locally.

Additional examples are documented via the test suite.
