# The latest ref in branch
set(ref 22441b505d9d9afc1e3002290820909846c24bdc)
set(branch sdk/12.0)
set(sha512 3fa66cc36a982db24b3f57925dd4cef99ead58f5e01ad2764638d16749b35c41f1ae5ad0cf7c73e4e62ad5391065ba2345e309ebf339b274532560d2c4820153)

vcpkg_find_patches()
vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO FFmpeg/nv-codec-headers
    REF "${ref}"
    SHA512 "${sha512}"
    PATCHES
        ${VCPKG_PATCHES}
        ${PATCHES}
)

# ====================================================
# Install the pkgconfig info for the `nvcodec` package
# ====================================================

# Windows
if(VCPKG_HOST_IS_WINDOWS)
    set(BUILD_SCRIPT ${CMAKE_CURRENT_LIST_DIR}\\build.sh)
    vcpkg_acquire_msys(MSYS_ROOT PACKAGES make pkg-config)
    set(BASH ${MSYS_ROOT}/usr/bin/bash.exe)

    message(STATUS "Building ${_csc_PROJECT_PATH} for Release")
    file(MAKE_DIRECTORY ${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET})

    # Make and deploy the ffnvcodec.pc file using MSYS
    # (so that FFmpeg can find it in the MSYS rootfs)
    vcpkg_execute_required_process(
        COMMAND ${BASH} --noprofile --norc "${BUILD_SCRIPT}"
            "${SOURCE_PATH}"
            "${CURRENT_PACKAGES_DIR}"
        WORKING_DIRECTORY ${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}
        LOGNAME build-${TARGET_TRIPLET}
    )

    if(NOT VCPKG_BUILD_TYPE)
      file(INSTALL "${SOURCE_PATH}/ffnvcodec.pc" DESTINATION "${CURRENT_PACKAGES_DIR}/debug/lib/pkgconfig")
    endif()

# Linux, etc.
else()
    FIND_PROGRAM(MAKE make)
    IF (NOT MAKE)
        MESSAGE(FATAL_ERROR "MAKE not found")
    ENDIF ()

    vcpkg_execute_required_process(
        COMMAND make PREFIX=$${CURRENT_PACKAGES_DIR}
        WORKING_DIRECTORY ${SOURCE_PATH}
        LOGNAME make-${TARGET_TRIPLET}
    )

    # FFmpeg uses pkgconfig to find ffnvcodec.pc, so install it where
    # FFMpeg's call to pkgconfig expects to find it.
    file(INSTALL "${SOURCE_PATH}/ffnvcodec.pc" DESTINATION "${CURRENT_PACKAGES_DIR}/lib/pkgconfig")
    if(NOT VCPKG_BUILD_TYPE)
      file(INSTALL "${SOURCE_PATH}/ffnvcodec.pc" DESTINATION "${CURRENT_PACKAGES_DIR}/debug/lib/pkgconfig")
    endif()
endif()

vcpkg_fixup_pkgconfig()

# Install the files to their default vcpkg locations
file(INSTALL "${SOURCE_PATH}/include" DESTINATION "${CURRENT_PACKAGES_DIR}")
vcpkg_install_copyright(FILE_LIST "${CURRENT_PORT_DIR}/copyright")
