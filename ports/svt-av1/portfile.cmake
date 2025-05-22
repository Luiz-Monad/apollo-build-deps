# The latest ref in branch master
set(ref 08c18ba0768ed3dbbff0903adc326fb3a7549bd9)

# Conditionally find and apply patches in numerical order
if(NOT "no-patches" IN_LIST FEATURES)
    file(GLOB PATCHES
        "${CMAKE_CURRENT_LIST_DIR}/patches/*.patch"
    )
    list(SORT PATCHES)
endif()
file(GLOB VCPKG_PATCHES
    "${CMAKE_CURRENT_LIST_DIR}/patches/vcpkg/*.patch"
)
list(SORT VCPKG_PATCHES)

vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO LizardByte-infrastructure/SVT-AV1
    SHA1 "${ref}"
    HEAD_REF master
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
