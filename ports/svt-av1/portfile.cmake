vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO LizardByte-infrastructure/SVT-AV1
    SHA1 08c18ba0768ed3dbbff0903adc326fb3a7549bd9
    HEAD_REF master
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
