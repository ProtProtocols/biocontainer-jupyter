FROM biocontainers/biocontainers:latest

# HACK to fix issues on some machines
# TODO: fix access on some machine when automatically created
USER biodocker
RUN mkdir -p /home/biodocker/.local/share/jupyter/kernels  && mkdir -p /home/biodocker/.local/share/jupyter/runtime 

USER root

# Install packages for R
RUN apt-get update  && apt-get install -y libnetcdf11 libnetcdf-dev libcurl3-dev libxml2-dev libssl-dev  && apt-get clean  && rm -rf /var/lib/apt/lists/*

# Install additional packages like tetex for jupyter
RUN apt-get update && apt-get install -y pandoc texlive-xetex && apt-get clean 

# upgrade to miniconda3
RUN  rm -rf /opt/conda &&  wget --quiet https://repo.anaconda.com/miniconda/Miniconda3-4.7.12.1-Linux-x86_64.sh -O ~/miniconda.sh && \
    /bin/bash ~/miniconda.sh -b -p /opt/conda && \
    rm ~/miniconda.sh && chmod 777 -R /opt/conda/

# Install jupyter (python 3 version)
#RUN apt-get update &&  apt-get install -y python3 python3-pip python3-pandas wkhtmltopdf  && apt-get clean 
RUN conda config --add channels conda-forge && conda config --set channel_priority strict 
#RUN update-alternatives --install /usr/bin/python python /usr/bin/python3.5 1
RUN conda install jupyterlab
RUN conda install rpy2  &&   jupyter serverextension enable --py jupyterlab --sys-prefix &&  conda install bokeh && conda install ipywidgets && conda install jupyterhub && conda install pandas && rm -rf /root/.cache
# jupyter nbextension enable --py --sys-prefix widgetsnbextension && 

RUN conda install jupyter_contrib_nbextensions && jupyter contrib nbextension install --user  && conda install jupyter_nbextensions_configurator && jupyter nbextensions_configurator enable --sys-prefix  && rm -rf /root/.cache

# Install python3 kernel
#RUN conda create -n ipykernel_py3 python=2 ipykernel  && bash -c 'source activate ipykernel_py3 && python -m ipykernel install'

# install iwidgets
RUN conda install ipywidgets && jupyter nbextension enable --py widgetsnbextension --sys-prefix

RUN ipython  kernel install

# Install R and R kernel
RUN conda install R-base && conda install r-irkernel

# install hide_code extension
RUN conda install hide_code &&  jupyter nbextension install --py hide_code --sys-prefix && jupyter nbextension enable --py hide_code --sys-prefix && jupyter serverextension enable --py hide_code --sys-prefix 


WORKDIR /home/biodocker

# configure jupyter (turn's off token and password validations)
COPY jupyter /home/biodocker/.jupyter

RUN mkdir IN  OUT LOG misc && rmdir bin

# Changes in web interface
#COPY page.html /usr/local/lib/python2.7/dist-packages/notebook/templates/
#COPY tree.html /usr/local/lib/python2.7/dist-packages/notebook/templates/
COPY page.html /usr/local/lib/python3.5/dist-packages/notebook/templates/
COPY tree.html /usr/local/lib/python3.5/dist-packages/notebook/templates/
COPY Eubic_logo.png /home/biodocker/misc
# default settings for notebooks
COPY notebook.json /home/biodocker/.jupyter/nbconfig/

# template for protocol notebook
COPY ["Example.ipynb", "."]

RUN chown -R biodocker:biodocker /home/biodocker

USER biodocker

EXPOSE 8888
CMD jupyter notebook --ip=0.0.0.0 --no-browser 
# CMD bash
