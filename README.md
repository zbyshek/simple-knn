# Simple KNN

## Compilation (Linux - WLS Ubuntu)
- Install CUDA (I use the version 12.8)
- Make sure that CUDA is avalable:
```bash
nvcc --version
```
- The code to run:
```bash
make clean
make release
```

## Compilation (Windows11)
### NOTE:
Compiling the code using the Makefile (which runs CMake) can be tricky.
You need to keep in mind that there is an issue with finding the **nvToolsExt** library.
I solved it by installing **nvToolsExt** from **CUDA 11.8** on top of my CUDA 12.8.
This approach is explained here:
https://discuss.pytorch.org/t/failed-to-find-nvtoolsext/179635/4

The second issue is connected to the Python torch library.
Adding an explicit find_library(TORCH_PYTHON_LIBRARY NAMES torch_python ...) was crucial.
This covers the PyTorch-specific PyBind code for at::Tensor.

For creating the Python binding, I use **Visual Studio Community 2022 (amd64)**.

- Install CUDA (I use the version 12.8)
- Make sure that CUDA is avalable:
```bash
nvcc --version
```
- The code to run:
```bash
make clean
make release
```

If you prefer to use the **setup.py** file for compilation and making the Python binding,
your steps could be the following:

- Launch your build in the **Visual Studio Developer Command Prompt**
- Setup and activate Python virtual environment
```bash
make build_venv
venv\Scripts\activate.bat
```
- Update your **PATH** environment variable to make sure that you pick the right compiler
(I have many installed, and this was crucial in my case):
```bash
set PATH=C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Tools\MSVC\14.40.33807\bin\Hostx64\x64;%PATH%
```

- Build and create python binding
```bash
make build # This step is essential for resolving dependencies.
python setup.py install
```
OR
```bash
make build # This step is essential for resolving dependencies
python setup.py bdist_wheel
```

## Using
- Create and switch into your project directory
```bash
mkdir path/to/folder
cd path/to/folder
```
- Create a Python Virtual Environment
```bash
python -m venv path/to/folder;
```
- Pip-install wheel, torch and numpy
```bash
pip install wheel
pip install numpy
pip install torch --extra-index-url https://download.pytorch.org/whl/cu124
```
- Use the built .whl file to install the module

**NOTE:**
Depens on how you built the .whl file, it could be located in:
```bash
./release/diff_surfel_rasterization-<version>/<whl file>
```
or
```bash
/dist/<whl file>
```
Install .whl file:
```bash
pip install path/to/whl_file
```
- Run Python and import the module:
```bash
import import diff_surfel_rasterization
```