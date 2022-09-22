# copy ROOT kernel into Jupyter
if [ "$ROOTSYS" != "" ]; then 
    mkdir -p /root/.local/share/jupyter/kernels
    cp -r $ROOTSYS/etc/notebook/kernels/root ~/.local/share/jupyter/kernels
    source scl_source enable rh-python38
    python3.8 -m pip --no-cache-dir install  root-pandas 
fi

# With RISE, a Jupyter notebook extension, you can instantly turn your jupyter notebook into a live reveal.js-based presentation.
jupyter-nbextension install rise --py --sys-prefix
jupyter-nbextension enable rise --py --sys-prefix

if [ "$1" != "" ]; then
    echo "Git Repo $1 requested..."
    cd /workspace/
    git clone $1
fi

export SHELL=/bin/bash

# setting up users
if [ "$OWNER" != "" ] && [ "$CONNECT_GROUP" != "" ]; then
    PATH=$PATH:/usr/sbin
    # Set the user's $DATA dir
    export DATA=/data/$OWNER
    if [ -z "$OWNER_UID" ] || [ -z "$CONNECT_GID" ]; then 
        echo "No UID or GID, cowardly aborting"
        exit 1
    else
        # Create the base group
        groupadd "$OWNER_GROUP" -g "$OWNER_GROUP_GID"
        # Create the user with no home directory (should already exist on NFS)
        # and the correct UID/GID
        useradd "$OWNER" -M -u "$OWNER_UID" -g "$OWNER_GROUP"
    fi
    # Match PS1 as we have it on the login nodes
    echo 'export PS1="[\A] \H:\w $ "' >> /etc/bash.bashrc
    # Chown the /workspace directory so users can create notebooks
    chown -R $OWNER: /workspace
    # Change to the user's homedir
    cd /home/$OWNER
    # get tutorial in.
    cp -r /ML_platform_tests/tutorial ~/.
    # Invoke Jupyter lab as the user
    su $OWNER -c "source scl_source enable rh-python38; jupyter lab --ServerApp.root_dir=/home/${OWNER} --no-browser --config=/usr/local/etc/jupyter_notebook_config.py"

# else
#    jupyter lab --allow-root --ServerApp.root_dir=${HOME} --no-browser --config=/usr/local/etc/jupyter_notebook_config.py
fi 
