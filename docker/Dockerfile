FROM julia:latest

RUN julia -e 'using Pkg; Pkg.add("ArgParse"); Pkg.add("HTTP"); Pkg.add("Sockets");'
RUN julia -e 'using Pkg; Pkg.add(url="https://github.com/frame-consulting/DiffFusionServer.jl#v0.0.7");'

RUN mkdir -p /usr/src/app
WORKDIR /usr/src/app
COPY app.jl /usr/src/app/

ENTRYPOINT [ "julia", "/usr/src/app/app.jl" ]
CMD [ "--host", "0.0.0.0", "--port", "2024" ]
