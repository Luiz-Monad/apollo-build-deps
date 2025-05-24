# The latest ref in branch
set(ref 08c18ba0768ed3dbbff0903adc326fb3a7549bd9)
set(branch v1.6.0)
set(sha512 0f790fe896d1e1db79cbb0162f786e2e074dddb6d3f8231a85e1e30e6f43976d2ae968878a6bb93603f0a6186ddc1f6fb525705b73ed0e52c7ba0b39de747a7a)

vcpkg_find_patches()
vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO LizardByte-infrastructure/SVT-AV1
    REF "${ref}"
    SHA512 "${sha512}"
    PATCHES
        ${VCPKG_PATCHES}
        ${PATCHES}
)

if(VCPKG_LIBRARY_LINKAGE STREQUAL "dynamic")
    message(FATAL_ERROR "This library does not support dynamic linking")
endif()

vcpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}/source"
    OPTIONS
        ${OPTIONS}
        -DENABLE_AVX512=ON
        -DBUILD_SHARED_LIBS=OFF
        -DBUILD_APPS=OFF
        -DENABLE_LIBNUMA=OFF
)

vcpkg_cmake_install()
vcpkg_copy_pdbs()
vcpkg_fixup_pkgconfig()

file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/include")

vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/LICENSE")
