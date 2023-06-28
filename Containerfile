ARG DIGEST=d8f9d38c21495b04d1cca99805fbb383856e19794265684019bf193c3b7d67f9
#FROM debian:bookworm-slim as build-env
FROM debian:bookworm-slim@sha256:${DIGEST} as build-env

ARG DEBIAN_FRONTEND=noninteractive

# define USER (ARG only available in build)
ARG USER=jupyter
RUN useradd --create-home --shell /bin/bash $USER \
  && id -u $USER \
  && id -g $USER
# show current workdir
ARG HOME="/home/$USER"
WORKDIR $HOME
RUN pwd

# install debian updates
RUN apt update && apt upgrade -y \
  # install jupyter
  && apt install -y --no-install-recommends jupyter-notebook \
  # install python math/ml libraries
  && apt install -y --no-install-recommends python3-numpy python3-matplotlib python3-scipy python3-pandas python3-torch python3-tqdm \
  # install ROOT required packages
  && apt install -y --no-install-recommends git dpkg-dev cmake g++ gcc binutils libx11-dev libxpm-dev libxft-dev libxext-dev libssl-dev \
  # install ROOT most common optional packages
  #&& apt install -y --no-install-recommends gfortran libpcre3-dev xlibmesa-glu-dev libglew-dev libftgl-dev libmysqlclient-dev libfftw3-dev libcfitsio-dev graphviz-dev libavahi-compat-libdnssd-dev libldap2-dev python-dev libxml2-dev libkrb5-dev libgsl0-dev qtwebengine5-dev \
  # make image smaller
  && rm -rf "/var/lib/apt/lists/*" \
  && rm -rf /var/cache/apt/archives

# switch to non-root user
USER $USER
RUN whoami
WORKDIR $HOME

# The latest stable branch gets updated automatically on each release.
# You may update your local copy by issuing a `git pull` command from within `root_src/`.
RUN mkdir root
WORKDIR $HOME/root
RUN git clone --branch latest-stable --depth=1 https://github.com/root-project/root.git root_src \
  && mkdir root_build root_install && cd root_build \
  # && check cmake configuration output for warnings or errors
  && cmake -DCMAKE_INSTALL_PREFIX=../root_install ../root_src \
  # if you have 4 cores available for compilation
  && cmake --build . -- install -j4 \
  && . ../root_install/bin/thisroot.sh
  #&& source ../root_install/bin/thisroot.sh
WORKDIR $HOME

EXPOSE 8888

ENTRYPOINT [ "bash", "-c", "source ./root/root_install/bin/thisroot.sh && /usr/bin/jupyter-notebook --no-browser --ip=0.0.0.0 --port=8888 --NotebookApp.token=''" ]
