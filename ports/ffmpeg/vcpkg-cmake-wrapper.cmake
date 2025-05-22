set(FFMPEG_PREV_MODULE_PATH ${CMAKE_MODULE_PATH})
list(APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_LIST_DIR})

cmake_policy(SET CMP0012 NEW)

# Detect if we use "our" find module or a vendored one
set(z_vcpkg_using_vcpkg_find_ffmpeg OFF)

# Detect targets created e.g. by VTK/CMake/FindFFMPEG.cmake
set(vcpkg_no_avcodec_target ON)
set(vcpkg_no_avutil_target ON)
if(TARGET FFmpeg::avcodec)
  set(vcpkg_no_avcodec_target OFF)
endif()
if(TARGET FFmpeg::avutil)
  set(vcpkg_no_avutil_target OFF)
endif()

_find_package(${ARGS})

# Fixup of variables and targets for (some) vendored find modules
if(NOT z_vcpkg_using_vcpkg_find_ffmpeg)

include(SelectLibraryConfigurations)

if(CMAKE_HOST_WIN32)
  set(PKG_CONFIG_EXECUTABLE "${CMAKE_CURRENT_LIST_DIR}/../../../@_HOST_TRIPLET@/tools/pkgconf/pkgconf.exe" CACHE STRING "" FORCE)
endif()

set(PKG_CONFIG_USE_CMAKE_PREFIX_PATH ON) # Required for CMAKE_MINIMUM_REQUIRED_VERSION VERSION_LESS 3.1 which otherwise ignores CMAKE_PREFIX_PATH

if(@WITH_AMF@)
  find_package(AMF CONFIG REQUIRED)
  list(APPEND FFMPEG_LIBRARIES AMF::AMF)
  if(vcpkg_no_avcodec_target AND TARGET FFmpeg::avcodec)
    target_link_libraries(FFmpeg::avcodec INTERFACE PkgConfig::AMF)
  endif()
endif()

if(@WITH_NVCODEC@)
  find_package(PkgConfig)
  pkg_check_modules(ffnvcodec IMPORTED_TARGET ffnvcodec)
  list(APPEND FFMPEG_LIBRARIES PkgConfig::ffnvcodec)
  if(vcpkg_no_avcodec_target AND TARGET FFmpeg::avcodec)
    target_link_libraries(FFmpeg::avcodec INTERFACE PkgConfig::ffnvcodec)
  endif()
endif()

if(@WITH_SVTAV1@)
  find_package(PkgConfig)
  pkg_check_modules(svtav1 IMPORTED_TARGET svtav1)
  list(APPEND FFMPEG_LIBRARIES PkgConfig::svtav1)
  if(vcpkg_no_avcodec_target AND TARGET FFmpeg::avcodec)
    target_link_libraries(FFmpeg::avcodec INTERFACE PkgConfig::svtav1)
  endif()
endif()

if(@WITH_X264@)
  find_package(PkgConfig)
  pkg_check_modules(x264 IMPORTED_TARGET x264)
  list(APPEND FFMPEG_LIBRARIES PkgConfig::x264)
  if(vcpkg_no_avcodec_target AND TARGET FFmpeg::avcodec)
    target_link_libraries(FFmpeg::avcodec INTERFACE PkgConfig::x264)
  endif()
endif()

if(@WITH_X265@)
  find_package(PkgConfig)
  pkg_check_modules(x265 IMPORTED_TARGET x265)
  list(APPEND FFMPEG_LIBRARIES PkgConfig::x265)
  if(vcpkg_no_avcodec_target AND TARGET FFmpeg::avcodec)
    target_link_libraries(FFmpeg::avcodec INTERFACE PkgConfig::x265)
  endif()
endif()

endif(NOT z_vcpkg_using_vcpkg_find_ffmpeg)
unset(z_vcpkg_using_vcpkg_find_ffmpeg)

set(FFMPEG_LIBRARY ${FFMPEG_LIBRARIES})

set(CMAKE_MODULE_PATH ${FFMPEG_PREV_MODULE_PATH})

unset(vcpkg_no_avcodec_target)
unset(vcpkg_no_avutil_target)
