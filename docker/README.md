This folder contains a server app and Docker file to build a container for running DiffFusionServer.

Build the image from the `docker/` subfolder via

    docker build --pull --rm -t diff-fusion-server:latest .

Then the container can be started via

    docker run --rm -it -p 2024:2024 diff-fusion-server:latest --port 2024

The server is listening on port 2024. If you can access the [info page](http://localhost:2024/api/v1/info) via browser then everything is set up.
