vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO LizardByte-infrastructure/x265_git
    SHA1 3bd3dd731b4b4c3fbbe5e513c16bc6ae481a0ec5
    HEAD_REF Release_3.5
    PATCHES
        patches/vcpkg-disable-install-pdb.patch
        patches/vcpkg-version.patch
        patches/vcpkg-linkage.diff
        patches/vcpkg-pkgconfig.diff
        patches/vcpkg-pthread.diff
        patches/vcpkg-compiler-target.diff
        patches/vcpkg-neon.diff
)

if(VCPKG_LIBRARY_LINKAGE STREQUAL "dynamic")
    message(FATAL_ERROR "This library does not support dynamic linking")
endif()

if(VCPKG_TARGET_ARCHITECTURE STREQUAL "x86" OR VCPKG_TARGET_ARCHITECTURE STREQUAL "x64")
    vcpkg_find_acquire_program(NASM)
    list(APPEND OPTIONS "-DNASM_EXECUTABLE=${NASM}")
    if(VCPKG_LIBRARY_LINKAGE STREQUAL "static" AND NOT VCPKG_TARGET_IS_WINDOWS AND NOT VCPKG_TARGET_IS_OSX)
        # x265 doesn't create sufficient PIC for asm, breaking usage
        # in shared libs, e.g. the libheif gdk pixbuf plugin.
        # Users can override this in custom triplets.
        list(APPEND OPTIONS "-DENABLE_ASSEMBLY=OFF")
    endif()
elseif(VCPKG_TARGET_IS_WINDOWS)
    list(APPEND OPTIONS "-DENABLE_ASSEMBLY=OFF")
endif()

# not currently supported for aarch64
if(VCPKG_TARGET_ARCHITECTURE STREQUAL "x64")
    list(APPEND OPTIONS "-DENABLE_HDR10_PLUS=ON")
endif()

vcpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}/source"
    OPTIONS
        ${OPTIONS}
        -DSTATIC_LINK_CRT=ON
        -DENABLE_SHARED=OFF
        -DENABLE_LIBNUMA=OFF
        -DENABLE_CLI=OFF
        "-DVERSION=${VERSION}"
    MAYBE_UNUSED_VARIABLES
        ENABLE_LIBNUMA
)

vcpkg_cmake_install()
vcpkg_copy_pdbs()
vcpkg_fixup_pkgconfig()

file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/include")

vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/COPYING")
