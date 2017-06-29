################################################################################################
# A function for automatic detection of the lowest CC of the installed NV GPUs
function(hip_cuda_detect_lowest_cc out_variable)
    set(__cufile ${PROJECT_BINARY_DIR}/detect_nvgpus_cc.cu)

    file(WRITE ${__cufile} ""
        "#include <cstdio>\n"
        "int main()\n"
        "{\n"
        "  int count = 0;\n"
        "  if (cudaSuccess != cudaGetDeviceCount(&count)) return -1;\n"
        "  if (count == 0) return -1;\n"
        "  int major = 1000;\n"
        "  int minor = 1000;\n"
        "  for (int device = 0; device < count; ++device)\n"
        "  {\n"
        "    cudaDeviceProp prop;\n"
        "    if (cudaSuccess == cudaGetDeviceProperties(&prop, device))\n"
        "      if (prop.major < major || (prop.major == major && prop.minor < minor)){\n"
        "        major = prop.major; minor = prop.minor;\n"
        "      }\n"
        "  }\n"
        "  std::printf(\"%d%d\", major, minor);\n"
        "  return 0;\n"
        "}\n")

    execute_process(COMMAND hipcc "-Wno-deprecated-gpu-targets" "--run" "${__cufile}"
                    WORKING_DIRECTORY "${PROJECT_BINARY_DIR}/CMakeFiles/"
                    RESULT_VARIABLE __nvcc_res OUTPUT_VARIABLE __nvcc_out
                    )

    if(__nvcc_res EQUAL 0)
        set(HIP_CUDA_lowest_cc ${__nvcc_out} CACHE INTERNAL "The lowest CC of installed NV GPUs" FORCE)
    endif()

    if(NOT HIP_CUDA_lowest_cc)
        set(HIP_CUDA_lowest_cc "20")
        set(${out_variable} ${HIP_CUDA_lowest_cc} PARENT_SCOPE)
    else()
        set(${out_variable} ${HIP_CUDA_lowest_cc} PARENT_SCOPE)
    endif()
endfunction()

################################################################################################
###  Non macro section
################################################################################################

if (HIP_PLATFORM STREQUAL "nvcc")
    set(HIP_NVCC_FLAGS " ${HIP_NVCC_FLAGS} -Wno-deprecated-gpu-targets") # Suppressing warnings
    hip_cuda_detect_lowest_cc(lowest_cc)
    if(lowest_cc LESS "30")
        set(HIP_NVCC_FLAGS "${HIP_NVCC_FLAGS}") # Do nothing
    else(lowest_cc LESS "30")
        set(HIP_NVCC_FLAGS "--gpu-architecture=sm_${lowest_cc}")
    endif(lowest_cc LESS "30")
    set(HIP_NVCC_FLAGS "${HIP_NVCC_FLAGS} -DHIP_CUDA_ARCH=${lowest_cc}0")
    #list(INSERT HIP_FLAGS2 0 "-DHIP_CUDA_ARCH=${lowest_cc}0")
endif()