# The latest ref in branch
set(ref 08c18ba0768ed3dbbff0903adc326fb3a7549bd9)
set(branch master)
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

string(COMPARE EQUAL "${VCPKG_LIBRARY_LINKAGE}" "dynamic" BUILD_SHARED_LIBS)

vcpkg_find_acquire_program(NASM)
vcpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}"
    OPTIONS
        "-DCMAKE_ASM_NASM_COMPILER=${NASM}"
        -DBUILD_SHARED_LIBS=${BUILD_SHARED_LIBS}
        -DENABLE_AVX512=ON
        -DBUILD_APPS=OFF
)

vcpkg_cmake_install()
vcpkg_copy_pdbs()
vcpkg_fixup_pkgconfig()

file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/include")

vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/LICENSE.md")
vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/LICENSE-BSD2.md")
