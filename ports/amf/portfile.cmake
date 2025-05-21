vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO GPUOpen-LibrariesAndSDKs/AMF
    SHA1 16f7d73e0b45c473e903e46981ed0b91efc4c091
    HEAD_REF master
    PATCHES
        patches/01-amf-colorspace.patch
        patches/02-idr-on-amf.patch
        patches/03-amfenc-disable-buffering.patch
        patches/04-amfenc-query-timeout.patch 
)

# Install the AMF headers to the default vcpkg location
file(INSTALL "${SOURCE_PATH}/amf/public/include/" DESTINATION "${CURRENT_PACKAGES_DIR}/include/AMF")
vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/LICENSE.txt")
