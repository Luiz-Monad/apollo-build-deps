# The latest ref in branch
set(ref 3bd3dd731b4b4c3fbbe5e513c16bc6ae481a0ec5)
set(branch Release_3.5)
set(sha512 21e0a16c4018af84a242c9c030fe416c544aff2fe06a25759930fe99ff18e0c4bc4e9ba5b19c8a1ade2ac1c5a0651fe633ec59fb8c895ca29c93f57282173c94)

vcpkg_find_patches()
vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO LizardByte-infrastructure/x265_git
    REF "${ref}"
    SHA512 "${sha512}"
    PATCHES
        ${VCPKG_PATCHES}
        ${PATCHES}
)

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

string(COMPARE EQUAL "${VCPKG_LIBRARY_LINKAGE}" "dynamic" ENABLE_SHARED)

# not currently supported for aarch64
if(VCPKG_TARGET_ARCHITECTURE STREQUAL "x64")
    list(APPEND OPTIONS "-DENABLE_HDR10_PLUS=ON")
endif()

vcpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}/source"
    OPTIONS
        ${OPTIONS}
        -DENABLE_SHARED=${ENABLE_SHARED}
        -DENABLE_PIC=ON
        -DENABLE_LIBNUMA=OFF
        -DENABLE_CLI=OFF
        "-DVERSION=${VERSION}"
    MAYBE_UNUSED_VARIABLES
        ENABLE_LIBNUMA
)

vcpkg_cmake_install()
vcpkg_copy_pdbs()
vcpkg_fixup_pkgconfig()

if(VCPKG_TARGET_IS_WINDOWS AND VCPKG_LIBRARY_LINKAGE STREQUAL "dynamic")
    vcpkg_replace_string("${CURRENT_PACKAGES_DIR}/include/x265.h" "#ifdef X265_API_IMPORTS" "#if 1")
endif()

file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/include")

vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/COPYING")
