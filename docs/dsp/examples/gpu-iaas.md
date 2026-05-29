# GPU IaaS with custom software and data

Infrastructure as a Service (IaaS) provides resources that you manage yourself.
It is a service for advanced customers that provides a lot of freedom to those
with the skills and responsibility to handle it.

## Topics

In this example you, as a Customer lead, will go through the steps of installing
software and uploading data to a GPU virtual machine you create on the AIDA Data
Hub Data Science Platform (DSP) for sensitive data.

This example assumes experience with Linux, and authority to initiate expense.

## Instructions

### 1. Launch a GPU enabled virtual machine

1. Visit the DSP Horizon customer self-service portal at [https://dsp.aida.scilifelab.se/](https://dsp.aida.scilifelab.se/)
2. Log in using your DSP Horizon credentials.
3. Pick the correct secure environment from the project selector drop down menu
   top left.
4. Add your SSH public key to your project by clicking Project > Compute >
   Key Pairs, then Import Public Key.
5. Create a GPU enabled virtual machine by clicking Instances > Launch instance,
   and
   1. In Details, Instance name: Put a good name for a compute server,
      like "Jupyter demo".
   2. In Source, click the up arrow icon next to an Ubuntu base image (such as Noble 24.04 or Resolute 26.04).
   3. In Flavor, click the up arrow icon next to a flavor that has GPU.
      Bigger is more expensive.
   4. If applicable: In Security Groups, click the up arrow icon next to
      `incoming`.
   5. In Key Pair, verify that your key is allocated.
   6. Click Launch instance.
6. Click Associate Floating IP > IP Address > pick one, fill in in next step.
7. Wait for Power State to become Running.

### 2. Configure your computer for easy access

Add to SSH-config (eg `~/.ssh/config`):

```ssh-config
Host jupyter-demo
  HostName [associated IP in Horizon]
  User ubuntu
  ProxyJump dspgateway
  ServerAliveInterval 10
  LocalForward 8888 localhost:8888
  LocalForward 6006 localhost:6006
  LocalForward 5901 localhost:5901

Host dspgateway
  HostName dsp.aida.scilifelab.se
  User [Identity in LifeScience Login]
```

This sets up your computer to use the DSP SSH access gateway when making SSH
connections to your VM. By default, DSP rejects SSH connections that are not
made through the SSH access gateway.

The configuration has two `Host` sections, one for the Virtual Machine you
created (_jupyter-demo_) and one for the gateway (_dspgateway_) which you will
use to "jump" into the secure environment.

The `ProxyJump` command in the _jupyter-demo_ section tells SSH that it should
connect to the VM by jumping through the host `dspgateway`. SSH authentication
to this gateway is done using Life Science Login, which is the default
authentication method for the DSP. To log accesses and match them to
the correct login account identity, your email address should be set as the
`User`, replacing the placeholder _[Identity in LifeScience Login]_.

`ServerAliveInterval` makes it easier to maintain a connection, and to detect
when it has gone stale.

The `LocalForwards` define SSH secured port forwards. They connect ports on your
computer with ports on your VM in the secure environment. They allow you to work
with Jupyter notebooks, TensorBoard, and VNC remote desktop running on the VM in
your secure environment as if though they were running on your computer.

### 3. Install software from public repositories that are trusted by the platform

DSP secure environments block connections by default. However, DSP provides an
inspecting http proxy that enables downloading software and security updates
from public repositories that are trusted by AIDA Data Hub. DSP data science
images are preconfigured to make transparent use of this proxy, as demonstrated
in this next step.

To configure the VM to use the DSP proxy, run the following command:

```bash
curl http://10.253.254.250/ | bash
```

If you want to inspect the script, you can run:

```bash
curl http://10.253.254.250/ > dspconfigscript
cat dspconfigscript
```

and then run:

```bash
bash dspconfigscript
```

#### 3.1 Install Nvidia GPU drivers

In order to be able to use the GPU, you need to install the Nvidia GPU drivers, we recommend installing version 580.

```bash
sudo apt update
sudo apt install nvidia-driver-580
```

#### 3.2 Clone the MONAI Tutorial repository and create a Python virtual environment

In this tutorial we will use the MONAI Tutorial repository, which is a collection of Jupyter notebooks that
demonstrate how to use the MONAI framework to build AI models specifically targeting medical image tasks
such as segmentation, classification, and detection.
Here, we clone the MONAI Tutorial repository and then create a Python virtual environment.
We do this inside a tmux virtual terminal so that work is kept persistent, so that running processes are not killed if connection is lost.

```bash
ssh jupyter-demo
tmux
git clone https://github.com/Project-MONAI/tutorials.git
cd tutorials
sudo apt update
sudo apt install python3-venv
sudo apt install python3.14-dev
python3 -m venv .venv
source .venv/bin/activate
pip install jupyterlab fire tensorboard
```

**Note**:
The restrictivity of the DSP inspecting http proxy is continually updated, to
adjust to updates in public repositories that make them more or less
appropriate for secure environments. For example, publicly accessible granular
download counters are increasingly popular despite constituting a trivially
exploitable data exfiltration method.

### 4. Upload own data

Most of the notebooks in the MONAI Tutorial have a link to a dataset which can be downloaded or they directly use Python functions to download the data.
However, within DSP we have restricted outgoing access to the internet, so you need to download the data to your own computer and upload it to your VM.

For example, the notebook [MedNIST_tutorial.ipynb](https://github.com/Project-MONAI/tutorials/blob/main/2d_classification/mednist_tutorial.ipynb) uses the [MedNIST dataset](https://mednist.org/) which can be downloaded from [https://github.com/Project-MONAI/MONAI-extra-test-data/releases/download/0.8.1/MedNIST.tar.gz](https://github.com/Project-MONAI/MONAI-extra-test-data/releases/download/0.8.1/MedNIST.tar.gz).

### 5. Inspect data in a remote desktop

1. Install TightVNC and XFCE desktop environment inside the VM.

```bash
sudo apt install tightvncserver xfce4 xfce4-goodies
mkdir ~/.vnc
echo -e '#!/bin/sh\nxrdb $HOME/.Xresources\nstartxfce4 &' > ~/.vnc/xstartup
chmod +x ~/.vnc/xstartup
sudo chown -R ubuntu:ubuntu ~/.vnc
```

2. Start a VNC server on your VM

```bash
tightvncserver -nolisten tcp -localhost :1
```

This starts a TightVNC server on the node. We also tell it to only listen to TCP
connections, and only those coming from localhost (this means other computers in
the same private network can't connect to the VNC server by default).

3. On your computer, point your VNC client of choice to `localhost:5901` to
   connect through the SSH port forward that you set up in step 2. You can for
   example use Remmina, which comes preinstalled on Ubuntu.

**Note**: In the future, AIDA Data Hub will provide ways to connect to a remote
desktop in a secure environment which do not require the user to have server
administrator skills.

### 6. Use a Jupyter notebook to train an AI model, and monitor progress graphically

1. Connect to your VM and start up the demo Jupyter notebook

```bash
ssh jupyter-demo
cd tutorials
source .venv/bin/activate
MONAI_DATA_DIRECTORY=/home/ubuntu/tutorials/Data jupyter lab --NotebookApp.token='' --NotebookApp.password='' --NotebookApp.open_browser=False --NotebookApp.ip='127.0.0.1' --no-browser
```

Note that we are setting the MONAI_DATA_DIRECTORY to the Data directory in the tutorials repository, the location where we will store the dataset.

Your Jupyter notebook is now ready to use, as long as you have this SSH
connection and its port forwards open.

To follow the [Spleen segmentation tutorial](https://github.com/Project-MONAI/tutorials/blob/main/2d_segmentation/spleen_segmentation_tutorial.ipynb), we need to first download the dataset on our local computer:

```bash
wget https://msd-for-monai.s3-us-west-2.amazonaws.com/Task09_Spleen.tar
```

Then we can upload the dataset to the VM:

```bash
scp Task09_Spleen.tar jupyter-demo:/home/ubuntu/tutorials/Data/
ssh jupyter-demo
cd tutorials/Data && tar -xvf Task09_Spleen.tar && rm Task09_Spleen.tar
```

2. Using a web browser on your computer, visit
   [http://127.0.0.1:8888](http://127.0.0.1:8888) to connect to your Jupyter
   notebook through the SSH port forward that you set up in step 2. Without it, you
   will not be able to connect.
3. Choose one of the following notebooks:
   - [spleen_segmentation_3d.ipynb](http://127.0.0.1:8888/lab/tree/3d_segmentation/spleen_segmentation_3d.ipynb)
   - [spleen_segmentation_3d_lightning.ipynb](http://127.0.0.1:8888/lab/tree/3d_segmentation/spleen_segmentation_3d_lightning.ipynb)
   - [spleen_segmentation_3d_visualization_basic.ipynb](http://127.0.0.1:8888/lab/tree/3d_segmentation/spleen_segmentation_3d_visualization_basic.ipynb)
4. Use Shift+Enter to run the cells manually in sequence. Edit if you like. You
   are now training AI models on GPU enabled IaaS compute resources in a secure
   environment on the AIDA Data Hub Data Science Platform.
5. Optional: Some of the notebooks create a TensorBoard interface, which can be
   used to monitor training progress graphically. You can either visualize it in the Jupyter notebook or in a separate browser tab by visiting [http://127.0.0.1:6006](http://127.0.0.1:6006).

## MONet Bundle: Segmentation with MONAI and nnU-Net

The current state-of-the-art in biomedical image segmentation is **nnU-Net** [1]. As a self-configuring deep learning framework, it has been widely adopted across numerous winning challenge entries and serves as the _de facto_ standard benchmark for medical image segmentation tasks.

Complementing this is **MONAI**, a comprehensive medical image analysis framework. MONAI provides an extensive suite of tools for building and training AI models across various tasks—not just segmentation, but also classification, detection, and more. Crucially, it introduces the concept of the **MONAI Bundle**, which streamlines packaging models and deploying them for inference, active learning, and federated learning.

The **MONet Bundle** bridges these two powerful tools by expanding the MONAI Bundle concept to include nnU-Net. This integration combines the cutting-edge segmentation performance of nnU-Net with the flexibility and adaptability of MONAI, allowing users to leverage nnU-Net as a backend for both robust training and streamlined inference.

**Learn More & Applications:**

- **Documentation & Code:** Explore the [MONet Bundle GitHub Repository](https://github.com/minnelab/MONet-Bundle).
- **Real-World Application:** Read about the application of the MONet Bundle for Federated Learning in PET-CT Lymphoma and Brain Tumor Segmentation [here](https://link.springer.com/chapter/10.1007/978-3-032-05663-4_10) [2].

---

### Example: Spleen Segmentation with MONet Bundle

To get started with an example using the MONet Bundle, download and extract the bundle using the following terminal commands:

```bash
# Download the MONet Bundle
wget https://raw.githubusercontent.com/minnelab/MONet-Bundle/main/MONetBundle.zip

# Unzip the downloaded bundle
unzip MONetBundle.zip
```

Once extracted, follow along with the [06_monet_bundle.ipynb](https://github.com/minnelab/MONet-Bundle/blob/main/06_monet_bundle.ipynb) tutorial notebook.

## References

[1] Isensee, F., Jaeger, P. F., Kohl, S. A., Petersen, J., & Maier-Hein, K. H. (2021). nnU-Net: a self-configuring method for deep learning-based biomedical image segmentation. Nature Methods, 18(2), 203-211.

[2] Bendazzoli, S. et al. (2026). MONet-FL: Extending nnU-Net with MONAI for Clinical Federated Learning. In: Zamzmi, G., et al. Bridging Regulatory Science and Medical Imaging Evaluation; and Distributed, Collaborative, and Federated Learning. MICCAI 2025. Lecture Notes in Computer Science, vol 16135. Springer, Cham. https://doi.org/10.1007/978-3-032-05663-4_10
