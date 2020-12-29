# Dockerfile for Reinforcment learning in Sofa-Framework
# with SofaPython3
# this section author is Arthur MacKeith -- amackeith@ttic.edu
# it is adapted from two dockerfiles -- one for the rl and one for the 
# sofa framework build environment
##############################################################################
# Reinforcment learning framework from github.com/cbschaff/dl
##############################################################################
FROM nvidia/cudagl:10.1-devel-ubuntu18.04

RUN apt-get update && apt-get upgrade -y

RUN apt-get install sudo

RUN echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

# runSofa cannot be used by the root user so this must be added.
RUN adduser --disabled-password --gecos '' sofauser && adduser sofauser sudo
#RUN useradd --create-home --shell /bin/bash sofauser && echo "sofauser:sofauser" | chpasswd && adduser sofauser sudo

# Set shell

USER sofauser
SHELL ["/bin/bash", "-c"]
WORKDIR /home/sofauser
ENV HOME="/home/sofauser"




# Install packages
RUN sudo apt-get install -y wget git vim libsm6 libxext6 libxrender-dev ffmpeg python-opengl

# install anaconda
RUN wget https://repo.anaconda.com/archive/Anaconda3-2019.10-Linux-x86_64.sh
RUN sudo chown sofauser:  Anaconda3-2019.10-Linux-x86_64.sh
RUN bash Anaconda3-2019.10-Linux-x86_64.sh -b -p $HOME/anaconda3
RUN sudo rm Anaconda3-2019.10-Linux-x86_64.sh
ENV PATH /home/sofauser/anaconda3/bin:$PATH
RUN conda update conda
RUN yes | conda update anaconda
RUN yes | conda update --all
RUN conda init bash
RUN source ~/.bashrc

# Install packages
RUN conda install -y -c pytorch pytorch torchvision
RUN conda install -y tensorflow-gpu==1.14.0
RUN pip install gin-config
RUN pip install gym[atari]
RUN pip install gym[box2d]



RUN sudo apt-get install -y freeglut3-dev
RUN conda install -y PyOpenGL
RUN pip install pygame PyOpenGL_accelerate


# Add a directory for rl python packages to be mounted
ENV PYTHONPATH /pkgs:$PYTHONPATH

###############################################################################
# End reinforcment learning dependencies (from cbschaff/dl on github)
###############################################################################
# Begin Setting up Sofa-Framework Build Environment
# adapted from sofaframework/sofabuilder_ubuntu on Dockerhub
# https://hub.docker.com/r/sofaframework/sofabuilder_ubuntu
###############################################################################

# if you uncomment this it forces a build without caching
#ADD "https://www.sofa-framework.org/rand/" ForceNoCache

RUN sudo apt-get update && sudo apt-get upgrade -y

# Install tools
RUN sudo apt-get install -y \
    apt-utils \
    git \
    net-tools \
    vim \
    wget \
    curl \
    zip \
    unzip

# Install compilers
RUN sudo apt-get install -y \
    build-essential \
    software-properties-common \
    ninja-build \
    gcc-7 g++-7 \
    clang \
    ccache

# Install core deps
RUN sudo apt-get install -y \
    libglew-dev \
    freeglut3-dev \
    zlib1g-dev \
    libeigen3-dev

# Install plugins deps
RUN sudo apt-get install -y \
    python2.7-dev python-pip python-numpy python-scipy \
    libpng-dev libjpeg-dev libtiff-dev \
    libblas-dev \
    liblapack-dev \
    libsuitesparse-dev \
    libavcodec-dev libavformat-dev libavutil-dev libswscale-dev \
    libassimp-dev \
    libbullet-dev \
    liboce-ocaf-dev \
    libzmq3-dev liboscpack-dev
ENV VM_HAS_ASSIMP="true"

# BulletColisionDetection is broken
ENV VM_HAS_BULLET="disabled"
ENV VM_HAS_OPENCASCADE="true"

# Install CMake
ADD https://github.com/Kitware/CMake/releases/download/v3.12.0/cmake-3.12.0-Linux-x86_64.sh /tmp
RUN sudo chmod a+x /tmp/cmake-3.12.0-Linux-x86_64.sh
RUN sudo bash /tmp/cmake-3.12.0-Linux-x86_64.sh --skip-license --prefix=/usr/local


# Install Qt
RUN sudo add-apt-repository -y ppa:beineri/opt-qt-5.12.6-bionic \
    && sudo apt-get update \
    && sudo apt-get install -y qt512-meta-full qt512charts-no-lgpl
ADD https://www.sofa-framework.org/wp-content/uploads/2020/06/QtInstallerFramework_3.0_Linux.zip /tmp
RUN sudo unzip /tmp/QtInstallerFramework_3.0_Linux.zip -d /builds && sudo chmod -R a+x /builds/Qt
ENV QTIFWDIR="/builds/Qt/Tools/QtInstallerFramework/3.0"
ENV PATH="${QTIFWDIR}/bin:${PATH}"

# Install Boost
RUN sudo add-apt-repository -y ppa:mhier/libboost-latest \
    && sudo apt-get update \
    && sudo apt-get install -y libboost1.67-dev

# Install CGAL
# Due to dependencies on Boost and Qt, we have to build CGAL
ADD https://github.com/CGAL/cgal/releases/download/releases/CGAL-4.14.3/CGAL-4.14.3.tar.xz /tmp
RUN sudo chown sofauser:sofauser /tmp/CGAL-4.14.3.tar.xz
RUN sudo apt-get install -y libgmp-dev libmpfr-dev
RUN sudo tar -xJf /tmp/CGAL-4.14.3.tar.xz --directory /tmp \
    && cd /tmp/CGAL-4.14.3 \
    && sudo mkdir build \
    && cd build \
    && sudo cmake -DCMAKE_BUILD_TYPE=Release -DWITH_CGAL_Core=TRUE -DWITH_CGAL_ImageIO=TRUE -DWITH_CGAL_Qt5=TRUE .. \
    && sudo make install
ENV VM_HAS_CGAL="true"
ENV VM_CGAL_PATH="/usr/local/lib/cmake/CGAL"

# Install CUDA
#RUN sudo apt-get install -y nvidia-cuda-toolkit
RUN sudo apt-get -o Dpkg::Options::="--force-overwrite" install --fix-broken -y nvidia-cuda-toolkit
ENV VM_HAS_CUDA="true"
ENV VM_CUDA_HOST_COMPILER="/usr/bin/gcc-6"
ENV VM_CUDA_ARCH="sm_50"

#############################################################################################
# Sofa-Framework Build environment End
#############################################################################################
# Install Plugins and build Begin
# this section author is Arthur MacKeith -- amackeith@ttic.edu
#############################################################################################

WORKDIR /builds



# Cleanup
RUN sudo apt-get clean -y \
    && sudo apt-get autoremove -y \
    && sudo rm -rf /tmp/*

# In-process env settings
COPY docker-entrypoint.sh /
RUN sudo chmod a+x /docker-entrypoint.sh




#my code starts here
RUN sudo apt-get update && sudo apt-get upgrade -y

RUN sudo apt-get install -y tree clang-8 ffmpeg
# Sudo for sofauserdd

# Python2 Dependencies for Model Order Reduction
RUN sudo apt-get -y install python-qt4 python-yaml python-cheetah python-nbformat


#Upgrade python3 from 3.6 to 3.7 for building SofaPython3
RUN sudo apt -y install python3.7 python3.7-dev
RUN sudo rm /usr/bin/python3 && sudo ln -s python3.7 /usr/bin/python3

# Not having these parametes set when building sofapython3 raises an error
RUN   git config --global user.email "place holder@example.com"
RUN   git config --global user.name "place holder"


# Python3 and Python2 Dependencies for jupyter-notebook
RUN sudo apt-get install -y build-essential python3.6 python3-pip python3-dev
RUN pip3 -q install pip --upgrade
RUN pip3 install jupyter numpy matplotlib scipy
RUN conda env export -n base

RUN python -m pip install ipykernel plotly iplot

RUN python -m pip install pybind11 && python -m pip install "pybind11[global]"


# Make a build directory to work in
RUN sudo chown -R sofauser:sofauser /builds

RUN mkdir -p /builds/src && mkdir -p /builds/build/master && mkdir -p /builds/plugins

#clone the master version of Sofa
RUN cd /builds/src && \
    git clone https://github.com/sofa-framework/sofa.git . && \
    git checkout v20.12_beta && \
    git checkout 184206f126acf0c5d45416fc23cb37baf1971fa5

# clone specific version of STLIB, SoftRobots, and ModelOrderReduction
RUN cd /builds/plugins && \
    git clone https://github.com/SofaDefrost/STLIB.git && \
    cd STLIB && \
    git checkout sofaPython3 && \
    git checkout f2d7f37

RUN cd /builds/plugins && \
    git clone https://github.com/SofaDefrost/SoftRobots.git && \
    cd SoftRobots && \
    git checkout e762f8759dfe812979bb92b1caf2aa18233d80a8

# MOR NOT supported by python3
#RUN cd /builds/plugins && \
#    git clone https://github.com/SofaDefrost/ModelOrderReduction.git && \
#    cd ModelOrderReduction && \
#    git checkout 83931e5697770e441e15dc3666c32f71fc038983


#clone python3
RUN cd /builds/plugins && \
    git clone https://github.com/sofa-framework/SofaPython3.git && \
    cd SofaPython3 && \
    git checkout ce1183a2ae51f2e2b722863e49cfc98464ca6ec3

COPY ./pluginsCMakeLists.txt /builds/plugins/CMakeLists.txt

#set this so it matches for the CMakeCache
RUN sudo rm /usr/bin/python && sudo ln -s python3.7 /usr/bin/python


# This Cache was made by using cmake-gui and x-docker and copying the resulting cache
# to outside the docker container, if changing the versions of any of the above git repos
# adds needed compile parameters or if you want to change the build you will need to
# stop the build at this point, run $x-docker run -it and then use cmake-gui to re-configure
# and create a new CMakeCache file.
COPY ./CMakeCachePython3.txt /builds/build/master/CMakeCache.txt
RUN sudo chown sofauser:sofauser /builds/build/master/CMakeCache.txt
# build sofa
RUN cd /builds/build/master && \
    cmake -c CMakeCache.txt && \
    ninja -j 8


# Cleanup
RUN sudo apt-get clean -y \
    && sudo apt-get autoremove -y \
    && rm -rf /tmp/*

##############################################################################################
# Build End
##############################################################################################
# Project setup begin
##############################################################################################
# make the build directory accessible to anyone
#####################################################################################################################################RUN sudo chmod -R a+wr /builds


# Add SofaPython3 to plugin_list
RUN cd /builds/build/master/lib && \
    cp plugin_list.conf.default plugin_list.conf && \
    echo $'\nSofaPython3 NO_VERSION\n' >> plugin_list.conf

#### user used to be here


RUN sudo mkdir -p /run/user/1000 && sudo chmod 0700 /run/user/1000/

# set up environment with bashrc
RUN sudo echo 'source /opt/qt512/bin/qt512-env.sh && exec "$@"' >> /etc/bash.bashrc
RUN sudo echo 'export QTIFWDIR="/builds/Qt/Tools/QtInstallerFramework/3.0"' >> /etc/bash.bashrc
RUN sudo echo 'export PYTHONPATH=/builds/build/master/lib/python3/site-packages:/builds/plugins/SofaPython3/splib:/builds/plugins/ModelOrderReduction/python:/builds/src/tools/sofa-launcher:/builds/plugins/STLIB/python3/src:/builds/plugins/SoftRobots/python3:$PYTHONPATH' >> /etc/bash.bashrc
RUN sudo echo 'export PATH=/builds/build/master/bin:$PATH' >> /etc/bash.bashrc
RUN sudo echo 'export PATH=$QTIFWDIR/bin:$PATH' >> /etc/bash.bashrc
RUN sudo echo 'export XDG_RUNTIME_DIR=/run/user/1000' >> /etc/bash.bashrc
RUN sudo echo 'export SOFA_ROOT=/builds/build/master/' >> /etc/bash.bashrc




# Python2 kernel for jupyter notebook
RUN python -m ipykernel install --user

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD /bin/bash -c "source ~/.bashrc && cd /home/sofauser/workdir/simple_control_policy/ && /bin/bash"



