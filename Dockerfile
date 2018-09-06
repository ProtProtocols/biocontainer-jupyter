FROM biocontainers/biocontainers:latest

# HACK to fix issues on some machines
# TODO: fix access on some machine when automatically created
USER biodocker
RUN mkdir -p /home/biodocker/.local/share/jupyter/kernels  && mkdir -p /home/biodocker/.local/share/jupyter/runtime 

USER root

# Install R
RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E298A3A825C0D65DFD57CBB651716619E084DAB9  && echo "deb http://cran.wu.ac.at/bin/linux/ubuntu xenial/" >> /etc/apt/sources.list  && apt-get update  && apt-get install -y libnetcdf11 libnetcdf-dev libcurl3-dev libxml2-dev libssl-dev r-base  && apt-get clean  && rm -rf /var/lib/apt/lists/*

# Install additional packages like tetex for jupyter
RUN apt-get update && apt-get install -y pandoc texlive-xetex && apt-get clean 

# Install jupyter (python 3 version)
RUN apt-get update &&  apt-get install -y python3 python3-pip python3-pandas wkhtmltopdf && apt-get clean &&  python3 -m pip install --upgrade pip
RUN update-alternatives --install /usr/bin/python python /usr/bin/python3.5 1
RUN pip3 --no-cache-dir install jupyter && pip3 --no-cache-dir install rpy2 --upgrade && pip3 --no-cache-dir install jupyterlab &&   jupyter serverextension enable --py jupyterlab --sys-prefix &&  pip3 --no-cache-dir install bokeh && pip3 --no-cache-dir install ipywidgets && pip3 --no-cache-dir install jupyterhub && pip3 --no-cache-dir install pandas --upgrade && rm -rf /root/.cache
# jupyter nbextension enable --py --sys-prefix widgetsnbextension && 

RUN pip3 --no-cache-dir install jupyter_contrib_nbextensions && jupyter contrib nbextension install --user  && pip3 --no-cache-dir install jupyter_nbextensions_configurator && jupyter nbextensions_configurator enable --sys-prefix  && rm -rf /root/.cache

# Install python3 kernel
#RUN conda create -n ipykernel_py3 python=2 ipykernel  && bash -c 'source activate ipykernel_py3 && python -m ipykernel install'

# install iwidgets
RUN pip3 --no-cache-dir install ipywidgets && jupyter nbextension enable --py widgetsnbextension --sys-prefix

RUN ipython  kernel install

# Install R kernel
RUN R -e "install.packages('devtools', repos='http://cran.rstudio.com/')"  -e "devtools::install_github('IRkernel/IRkernel')" -e "IRkernel::installspec()"

# install hide_code extension
RUN pip3 --no-cache-dir install hide_code &&  jupyter nbextension install --py hide_code --sys-prefix && jupyter nbextension enable --py hide_code --sys-prefix && jupyter serverextension enable --py hide_code --sys-prefix 


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
