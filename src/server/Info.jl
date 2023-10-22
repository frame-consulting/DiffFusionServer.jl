
"""
    const _INFO_STRING

An info string with API details.
"""
const _INFO_STRING =
"""
DiffFusionServer.jl API

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

"""
