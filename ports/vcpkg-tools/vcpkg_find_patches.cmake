#[===[.md:
# vcpkg_find_patches

Find and collect patch files from standard vcpkg patch directories.

```cmake
vcpkg_find_patches(
    [PATCHES_VAR <variable_name>]
    [VCPKG_PATCHES_VAR <variable_name>]
    [NO_FEATURE_PATCHES]
    [FEATURE_PATCHES <feature1> <feature2> ...]
)
```

This function searches for patch files in the standard vcpkg patch directories and sorts them
in numerical order for consistent application. By default, it will find patches in both
the general patches directory and the vcpkg-specific patches directory.

`PATCHES_VAR` specifies the variable name to store the general patches (defaults to PATCHES).
`VCPKG_PATCHES_VAR` specifies the variable name to store the vcpkg-specific patches (defaults to VCPKG_PATCHES).
`NO_FEATURE_PATCHES` disables the conditional feature-based patch finding.
`FEATURE_PATCHES` specifies feature-specific patch directories to search. For each feature,
patches are searched in `patches/<feature>/*.patch` and stored in `<FEATURE>_PATCHES` variable.
Feature patches are only collected if the corresponding "no-<feature>-patches" feature is not enabled.

The function respects the "no-patches" feature to conditionally skip general patches,
but always finds vcpkg-specific patches unless disabled.

## Examples

```cmake
# Basic usage - populates PATCHES and VCPKG_PATCHES variables
vcpkg_find_patches()

# With feature-specific patches
vcpkg_find_patches(
    FEATURE_PATCHES cbs MF vaapi
)
# This creates CBS_PATCHES, MF_PATCHES, and VAAPI_PATCHES variables

# Custom variable names with features
vcpkg_find_patches(
    PATCHES_VAR MY_PATCHES
    VCPKG_PATCHES_VAR MY_VCPKG_PATCHES
    FEATURE_PATCHES cbs MF
)

# Disable all feature-conditional patches
vcpkg_find_patches(NO_FEATURE_PATCHES)
```
#]===]

if(Z_VCPKG_FIND_PATCHES_GUARD)
    return()
endif()
set(Z_VCPKG_FIND_PATCHES_GUARD ON CACHE INTERNAL "guard variable")

function(vcpkg_find_patches)
    cmake_parse_arguments(PARSE_ARGV 0 "arg" "NO_FEATURE_PATCHES" "PATCHES_VAR;VCPKG_PATCHES_VAR" "FEATURE_PATCHES")

    if(DEFINED arg_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "vcpkg_find_patches was passed extra arguments: ${arg_UNPARSED_ARGUMENTS}")
    endif()

    if(NOT arg_PATCHES_VAR)
        set(arg_PATCHES_VAR "PATCHES")
    endif()

    if(NOT arg_VCPKG_PATCHES_VAR)
        set(arg_VCPKG_PATCHES_VAR "VCPKG_PATCHES")
    endif()

    # Clear the output variables
    set("${arg_PATCHES_VAR}" "" PARENT_SCOPE)
    set("${arg_VCPKG_PATCHES_VAR}" "" PARENT_SCOPE)

    # Conditionally find and collect general patches in numerical order
    if(NOT arg_NO_FEATURE_PATCHES AND NOT "no-patches" IN_LIST FEATURES)
        file(GLOB patches_list
            "${CMAKE_CURRENT_LIST_DIR}/patches/*.patch"
        )
        if(patches_list)
            list(SORT patches_list)
            set("${arg_PATCHES_VAR}" "${patches_list}" PARENT_SCOPE)
        endif()

        # Process feature-specific patches
        foreach(feature IN LISTS arg_FEATURE_PATCHES)
            if(NOT "no-${feature}-patches" IN_LIST FEATURES)
                string(TOUPPER "${feature}" feature_upper)
                file(GLOB feature_patches_list
                    "${CMAKE_CURRENT_LIST_DIR}/patches/${feature}/*.patch"
                )
                if(feature_patches_list)
                    list(SORT feature_patches_list)
                    set("${feature_upper}_PATCHES" "${feature_patches_list}" PARENT_SCOPE)
                else()
                    set("${feature_upper}_PATCHES" "" PARENT_SCOPE)
                endif()
            else()
                string(TOUPPER "${feature}" feature_upper)
                set("${feature_upper}_PATCHES" "" PARENT_SCOPE)
            endif()
        endforeach()
    endif()

    # Find and collect vcpkg-specific patches in numerical order
    file(GLOB vcpkg_patches_list
        "${CMAKE_CURRENT_LIST_DIR}/patches/vcpkg/*.patch"
    )
    if(vcpkg_patches_list)
        list(SORT vcpkg_patches_list)
        set("${arg_VCPKG_PATCHES_VAR}" "${vcpkg_patches_list}" PARENT_SCOPE)
    endif()
endfunction()
