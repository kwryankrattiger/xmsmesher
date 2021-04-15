# Import the XMS::Mesher target
find_package(Boost QUIET REQUIRED log_setup log system filesystem serialization timer)
include(${CMAKE_CURRENT_LIST_DIR}/xmsmesher-targets.cmake)

# Get the root installation dir
get_filename_component(_IMPORT_PREFIX "${CMAKE_CURRENT_LIST_FILE}" PATH)
get_filename_component(_IMPORT_PREFIX "${_IMPORT_PREFIX}" PATH)
get_filename_component(_IMPORT_PREFIX "${_IMPORT_PREFIX}" PATH)
get_filename_component(_IMPORT_PREFIX "${_IMPORT_PREFIX}" PATH)
if(_IMPORT_PREFIX STREQUAL "/")
  set(_IMPORT_PREFIX "")
endif()

include(GNUInstallDirs)

# Set the FindXMSCore variables
set(XMSMesher_FOUND TRUE)
set(XMSMesher_PREFIX ${CMAKE_CURRENT_LIST_DIR})
set(XMSMesher_LIBRARY_DIRS "${_IMPORT_PREFIX}/${CMAKE_INSTALL_LIBDIR}")
set(XMSMesher_INCLUDE_DIRS "${_IMPORT_PREFIX}/${CMAKE_INSTALL_INCLUDEDIR}")
set(XMSMesher_LIBRARIES XMS::Mesher)
set(XMSMesher_VERSION 5.2.0)
