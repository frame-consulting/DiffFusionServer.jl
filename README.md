# DiffFusionServer

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://frame-consulting.github.io/DiffFusionServer.jl/stable/)

[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://frame-consulting.github.io/DiffFusionServer.jl/dev/)

[![Build Status](https://github.com/frame-consulting/DiffFusionServer.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/frame-consulting/DiffFusionServer.jl/actions/workflows/CI.yml?query=branch%3Amain)

[![Coverage](https://codecov.io/gh/frame-consulting/DiffFusionServer.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/frame-consulting/DiffFusionServer.jl)

The DiffFusionServer.jl package provides a REST API for the [DiffFusion.jl](https://github.com/frame-consulting/DiffFusion.jl) exposure simulation framework.

The server accepts HTTP requests with methods GET, POST, DELETE. The methods are used to query and modify an object repository.

The POST method is used to create objects via DiffFusion methods. Objects are labelled with an identifier (*alias*). Subsequent GET method requests retrieve the object. Requests with DELETE method allow deleting objects in the repository.

Details of requests are stored in the request header and the request body. The request body is interpreted as JSON format. Results from requests are stored in the response body. Results are also interpreted as JSON format.

