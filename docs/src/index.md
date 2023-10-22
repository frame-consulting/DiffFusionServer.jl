```@meta
CurrentModule = DiffFusionServer
```

# DiffFusionServer

Documentation for [DiffFusionServer](https://github.com/frame-consulting/DiffFusionServer.jl).

## Getting Started

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
server = HTTP.serve!(router, Sockets.localhost, 80)
```

Now you can visit the end point [localhost](http://localhost/api/v1/info) with your browser. This should display an info text of the API.

Alternatively, you can query the server via `HTTP` in Julia.

```
resp = HTTP.get("http://localhost/api/v1/info")
display(resp)
```

Finally, you can close the server via

```
close(server)
```


## API

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
