# This is the CMakeLists.txt file was created due to simplification of
# the build process using Makefile by Alexey Mazurenko.

# Project setup
cmake_minimum_required(VERSION 3.20)
project(simple_knn LANGUAGES CUDA CXX)

# Language standards
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_EXTENSIONS OFF)
set(CMAKE_CUDA_STANDARD 17)
enable_language(CUDA)

# CUDA settings
if(WIN32)
    set(CMAKE_CUDA_FLAGS "${CMAKE_CUDA_FLAGS} -Xcompiler=/wd4624")
endif()
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS}")

# Python setup
find_package(Python3 REQUIRED COMPONENTS Development)

# NvToolsExt setup
if (WIN32 AND NOT TARGET CUDA::nvToolsExt)
    find_library(NVTOOLSEXT_LIB
        NAMES nvToolsExt64_1 nvToolsExt
        PATHS "${CUDAToolkit_LIBRARY_DIRS}"
        ${CMAKE_CURRENT_SOURCE_DIR}/third_party/windows/NvToolsExt/lib/x64
    )
    message(STATUS "NVTOOLSEXT_LIB: ${NVTOOLSEXT_LIB}")
    add_library(CUDA::nvToolsExt INTERFACE IMPORTED)
    set_target_properties(CUDA::nvToolsExt PROPERTIES
        INTERFACE_INCLUDE_DIRECTORIES "${CUDAToolkit_INCLUDE_DIRS}"
        INTERFACE_LINK_LIBRARIES "${NVTOOLSEXT_LIB}"
    )
endif()

# PyTorch setup
if(WIN32)
    find_package(
        Torch REQUIRED
        PATHS
        venv/Lib/site-packages/torch/share/cmake/Torch
    )
else()
    find_package(
        Torch REQUIRED
        PATHS
        venv/lib/python${Python3_VERSION_MAJOR}.${Python3_VERSION_MINOR}/site-packages/torch/share/cmake/Torch
    )
endif()

# Pybind11 setup
include(FetchContent)
FetchContent_Declare(
    pybind11
    GIT_REPOSITORY https://github.com/pybind/pybind11.git
    GIT_TAG stable
)
FetchContent_MakeAvailable(pybind11)

# Main library
add_library(simple_knn STATIC
    src/simple_knn.cu
    src/simple_knn.h
    src/spatial.cu
    src/spatial.h
)
set_target_properties(simple_knn PROPERTIES
    CUDA_SEPARABLE_COMPILATION OFF
    CUDA_ARCHITECTURES 86
)
target_include_directories(
    simple_knn
    PUBLIC
    ${CMAKE_CURRENT_SOURCE_DIR}/src
    ${TORCH_INCLUDE_DIRS}
    ${Python3_INCLUDE_DIRS}
    PRIVATE
    ${CMAKE_CUDA_TOOLKIT_INCLUDE_DIRECTORIES}
)

# Python bindings
set(
    simple_knn_py_module simple_knn_C
    CACHE STRING "The name of the pyd to build"
)
pybind11_add_module(
    ${simple_knn_py_module}
    src/spatial.cu
    src/simple_knn.cu
    src/ext.cpp
)
target_include_directories(${simple_knn_py_module}
    PUBLIC
    ${CMAKE_CURRENT_SOURCE_DIR}/src
    ${CMAKE_CUDA_TOOLKIT_INCLUDE_DIRECTORIES}
    ${TORCH_INCLUDE_DIRS}
    ${Python3_INCLUDE_DIRS}
)
target_link_libraries(${simple_knn_py_module}
  PRIVATE pybind11::module
  CUDA::cudart
  ${TORCH_LIBRARIES}
  Python3::Python
)
# PyTorch Python library
find_library(TORCH_PYTHON_LIBRARY
    NAMES torch_python
    HINTS
      "${TORCH_INSTALL_PREFIX}/lib"
      "${TORCH_INSTALL_PREFIX}"
      "${TORCH_LIBRARY_DIRS}"
      "${CMAKE_CURRENT_SOURCE_DIR}/venv/Lib/site-packages/torch/lib"
)
if (TORCH_PYTHON_LIBRARY)
    message(STATUS "Found torch_python: ${TORCH_PYTHON_LIBRARY}")
    target_link_libraries(${simple_knn_py_module}
      PRIVATE
        ${TORCH_PYTHON_LIBRARY}
    )
else()
    message(
        WARNING
        "Could not find torch_python.lib; you may still have link errors."
    )
endif()
set_target_properties(
    ${simple_knn_py_module} PROPERTIES
    CUDA_INCLUDE_DIRS "${CMAKE_CURRENT_SOURCE_DIR}/src"
    CUDA_ARCHITECTURES "86"
    CUDA_SEPARABLE_COMPILATION OFF
)

# Status messages
message( STATUS "Python3_INCLUDE_DIRS = ${Python3_INCLUDE_DIRS}" )
message(STATUS "Python3_LIBRARIES: ${Python3_LIBRARIES}")
message(STATUS "Python3_LIBRARY_DIRS: ${Python3_LIBRARY_DIRS}")
message (STATUS "TORCH_INCLUDE_DIRS: ${TORCH_INCLUDE_DIRS}")
message (STATUS "TORCH_LIBRARIES: ${TORCH_LIBRARIES}")
message (STATUS "TORCH_PYTHON_LIBRARY: ${TORCH_PYTHON_LIBRARY}")
message (STATUS "CMAKE_CUDA_TOOLKIT_INCLUDE_DIRECTORIES: ${CMAKE_CUDA_TOOLKIT_INCLUDE_DIRECTORIES}")
message (STATUS "Configuring done.")
