#
# Copyright (C) 2023, Inria
# GRAPHDECO research group, https://team.inria.fr/graphdeco
# All rights reserved.
#
# This software is free for non-commercial, research and evaluation use
# under the terms of the LICENSE.md file.
#
# For inquiries contact  george.drettakis@inria.fr
#

import os
from setuptools import setup
from torch.utils.cpp_extension import CUDAExtension, BuildExtension

os.environ["DISTUTILS_USE_SDK"] = "1"

cxx_compiler_flags = []

if os.name == 'nt':
    cxx_compiler_flags.append("/wd4624")

setup(
    name="simple_knn",
    ext_modules=[
        CUDAExtension(
            name="simple_knn.simple_knn_C",
            sources=[
            "src/spatial.cu",
            "src/simple_knn.cu",
            "src/ext.cpp"],
            extra_compile_args={"nvcc": [], "cxx": cxx_compiler_flags})
        ],
    cmdclass={
        'build_ext': BuildExtension
    }
)
