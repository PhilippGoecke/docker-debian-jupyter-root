docker build -t jupyter:0.1 -f Containerfile .
docker run --interactive --tty -p 8888:8888 jupyter:0.1
