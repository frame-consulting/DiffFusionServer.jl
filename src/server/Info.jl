
"""
    const _INFO_STRING

An info string with API details.
"""
const _INFO_STRING =
"""
<html>
<body>
<h1>DiffFusionServer.jl API</h1>
<p>
This is a summary of the API to serve DiffFusion functionality via HTTP.
</p>
<p>
The API implements an object repository. Individual objects are accessible
via their 'alias' key.
</p>
<p>
Endpoints:
</p>
<p>
GET: [api_path]/[version]/info
</p>
<ul>
  <li>Return this info message.</li>
</ul>
<p>
GET: [api_path]/[version]/aliases
</p>
<ul>
  <li>Return the list of aliases in object repository.</li>
</ul>
<p>
POST: [api_path]/[version]/ops
</p>
<ul>
  <li>This method implements the main API logic:</li>
  <ul>
    <li>Load request body into OrderedDict 'd'.</li>
    <li>Retrieve 'alias' field from  request header.</li>
    <li>Retrieve operation field 'op' from request header.</li>
    <li>Process OrderedDict 'd' according to operation 'op'.</li>
    <li>Store resulting object in object repository with key 'alias'.</li>
  </ul>
  <li>Operations 'op' are</li>
  <ul>
    <li>'COPY': copy body as OrderedDict to repository,</li>
    <li>'BUILD': de-serialise object and store in repository.</li>
  </ul>
</ul>
<p>
POST: [api_path]/[version]/bulk
</p>
<ul>
  <li>This method implements the POST method for a list of object.</li>
  <ul>
    <li>Request body contains a list of two-element lists.</li>
    <li>Each two-element list contains the object 'alias' and the dictionary specifying the object creation.</li>
    <li>Object creation follows the method for single-object POST method.</li>
  </ul>
</ul>
<p>
GET: [api_path]/[version]/ops
</p>
<ul>
  <li>Retrieve 'alias' field from  request header, serialise object from repository and return via body.</li>
</ul>
<p>
GET: [api_path]/[version]/bulk
</p>
<ul>
  <li>This method implements the GET method for a list of objects.</li>
  <ul>
    <li>Request body contains a list of 'alias' keys.</li>
    <li>Response body contains a list of serialised objects.</li>
  </ul>
</ul>
<p>
DELETE: [api_path]/[version]/ops/
</p>
<ul>
  <li>Retrieve 'alias' field from  request header and delete the object with given alias.</li>
</up>
</body>
</html>
"""
