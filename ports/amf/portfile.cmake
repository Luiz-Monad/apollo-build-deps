# The latest ref in branch
set(ref 16f7d73e0b45c473e903e46981ed0b91efc4c091)
set(branch master)
set(sha512 c46c6014c4b284536f2f0aa7a63a40e110a9ba19c3387557193013ff15d98cfb1e7f7ee30bbb809be35384b8a286c00f8f071a911873ce1353023a94f7e3cc01)

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
    REPO GPUOpen-LibrariesAndSDKs/AMF
    REF "${ref}"
    SHA512 "${sha512}"
    PATCHES
        ${VCPKG_PATCHES}
        ${PATCHES}
)

# Install the AMF headers to the default vcpkg location
file(INSTALL "${SOURCE_PATH}/amf/public/include/" DESTINATION "${CURRENT_PACKAGES_DIR}/include/AMF")
vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/LICENSE.txt")
