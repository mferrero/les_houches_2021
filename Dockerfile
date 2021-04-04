FROM ubuntu:focal
ARG LLVM=10

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
      clang-${LLVM} \
      cmake \
      g++ \
      gfortran \
      make \
      git \
      vim \
      lldb-${LLVM} \
      hdf5-tools \
      libclang-${LLVM}-dev \
      libc++-${LLVM}-dev \
      libc++abi-${LLVM}-dev \
      libomp-${LLVM}-dev \
      libgfortran4 \
      libgmp-dev \
      libboost-dev \
      libhdf5-dev \
      libblas-dev \
      liblapack-dev \
      libopenmpi-dev \
      libfftw3-dev \
      libnfft3-dev \
      openmpi-bin \
      openmpi-common \
      openmpi-doc \
      python3-clang-${LLVM} \
      python3-dev \
      python3-mako \
      python3-matplotlib \
      python3-mpi4py \
      python3-numpy \
      python3-scipy \
      jupyter-notebook \
      \
      sudo \
      openssh-client \
      curl \
      && \
    apt-get autoremove --purge -y && \
    apt-get autoclean -y && \
    rm -rf /var/cache/apt/* /var/lib/apt/lists/*

ARG ARCH=x86-64
ENV INSTALL=/usr \
    PYTHONPATH=/usr/lib/python3.8/site-packages \
    CMAKE_PREFIX_PATH=/usr/lib/cmake/triqs \
    PYTHON_VERSION=3.8 \
    CC=clang-${LLVM} CXX=clang++-${LLVM} CXXFLAGS="-stdlib=libc++ -march=${ARCH}"

ARG NB_USER=triqs
ARG NB_UID=1000
RUN useradd -u $NB_UID -m $NB_USER && \
    echo 'triqs ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
ENV HOME /home/$NB_USER

COPY . ${HOME}
WORKDIR /home/$NB_USER

ARG NCORES=10
ARG BRANCH=3.0.x
RUN set -ex ; \
  for pkg in triqs cthyb ; do \
    mkdir -p $pkg; cd $pkg; \
    git clone https://github.com/TRIQS/$pkg --branch $BRANCH --depth 1 src ; \
    mkdir -p build ; cd build ; \
    cmake ../src -DCMAKE_INSTALL_PREFIX=$INSTALL ; \
    make -j$NCORES ; \
    make install ; \
    cd ../.. ; \
  done ; \
  mkdir -p ctint; cd ctint; \
  git clone https://github.com/mferrero/les_houches.git src ; \
  mkdir -p build ; cd build ; \
  cmake ../src -DCMAKE_INSTALL_PREFIX=$INSTALL ; \
  make -j$NCORES ; \
  make install

ENV CMAKE_PREFIX_PATH=/usr/lib/cmake/triqs \
    CPATH=/usr/include/openmpi:/usr/include/hdf5/serial:$CPATH

RUN chown -R ${NB_UID} ${HOME}
USER ${NB_USER}
WORKDIR /home/$NB_USER

EXPOSE 8888
CMD ["jupyter","notebook","--ip","0.0.0.0"]
