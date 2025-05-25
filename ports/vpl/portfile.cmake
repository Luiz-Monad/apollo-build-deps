# The latest ref in branch
set(ref c45b5d786bf7cdabbe49ff1bab78693ad78feb78)
set(branch main)
set(sha512 36f8817ae37013058753ae56383d9301c8214472e0b83d903e68b3aefa7d258510f5ed9f72f2ec15da74467797d3ccefc4cfa52f9eaff502a967b6ef7bc67536)

vcpkg_find_patches()
vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO intel/libvpl
    REF "${ref}"
    SHA512 "${sha512}"
    PATCHES
        ${VCPKG_PATCHES}
        ${PATCHES}
)

string(COMPARE EQUAL "${VCPKG_LIBRARY_LINKAGE}" "dynamic" ENABLE_SHARED)

vcpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}"
    OPTIONS
        -DBUILD_SHARED_LIBS=${BUILD_SHARED_LIBS}
        -DINSTALL_DEV=ON
        -DINSTALL_EXAMPLES=OFF
        -DBUILD_EXAMPLES=OFF
)

vcpkg_cmake_install()
vcpkg_copy_pdbs()
vcpkg_fixup_pkgconfig()

file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/include")
file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/share")

vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/LICENSE")
