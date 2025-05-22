# The latest ref in branch master
set(ref 16f7d73e0b45c473e903e46981ed0b91efc4c091)

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
    SHA1 "${ref}"
    HEAD_REF master
    PATCHES
        ${VCPKG_PATCHES}
        ${PATCHES}
)

# Install the AMF headers to the default vcpkg location
file(INSTALL "${SOURCE_PATH}/amf/public/include/" DESTINATION "${CURRENT_PACKAGES_DIR}/include/AMF")
vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/LICENSE.txt")
