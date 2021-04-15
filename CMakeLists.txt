cmake_minimum_required(VERSION 3.1.2)
cmake_policy(SET CMP0015 NEW) # Link Directory Pathing
set(CMAKE_DEBUG_POSTFIX _d)

if (APPLE OR WIN32)
    set(CMAKE_CXX_STANDARD 17)
else()
    set(CMAKE_CXX_STANDARD 14)
endif()

if (APPLE)
  set(CMAKE_POSITION_INDEPENDENT_CODE False)
else()
  set(CMAKE_POSITION_INDEPENDENT_CODE True)
endif()

project(xmsmesher C CXX)

include(GNUInstallDirs)

set(BUILD_SHARED_LIBS OFF CACHE BOOL "Enable/Disable building shared libraries")
set(BUILD_TESTING NO CACHE BOOL "Enable/Disable testing")
set(XMS_BUILD_MODE "CONAN" CACHE STRING "Target packing system to build for.")
set_property(CACHE XMS_BUILD_MODE PROPERTY STRINGS "CONAN;CONDA;CMAKE")
set(XMS_BUILD NO CACHE BOOL "Set this if you want to use this package with XMS.")
set(CONDA_PREFIX "" CACHE PATH "Path to the conda environment used to build.")
set(ENABLE_PYTHON NO CACHE BOOL "Set this if you want to build the python bindings.")
set(PYTHON_TARGET_VERSION 3.6 CACHE STRING "Version of python to link to for python wrapping.")
set(XMS_TEST_PATH ${PROJECT_SOURCE_DIR}/test_files/ CACHE PATH "Path to test files for testing")
set(XMS_VERSION "5.2.0" CACHE STRING "Library Version")

add_definitions(-DXMS_VERSION=\"${XMS_VERSION}\")

if(ENABLE_PYTHON AND BUILD_TESTING)
  message(FATAL_ERROR "Cannot build python module when testing is enabled")
endif()

if(XMS_BUILD_MODE STREQUAL "CONDA")
  include(${CMAKE_CURRENT_LIST_DIR}/condabuildinfo.cmake)
elseif(XMS_BUILD_MODE STREQUAL "CMAKE")
  if (BUILD_SHARED_LIBS)
    set(Boost_USE_STATIC_LIBS OFF)
  else ()
    set(Boost_USE_STATIC_LIBS ON)
  endif ()
  find_package(Boost QUIET REQUIRED log_setup log system filesystem serialization timer)
  find_package(XMSCore QUIET REQUIRED
    NAMES xms xmscore)
  find_package(XMSGrid QUIET REQUIRED
    NAMES xms xmsgrid)
  find_package(XMSInterp QUIET REQUIRED
    NAMES xms xmsinterp)
  list(APPEND EXT_INCLUDE_DIRS ${XMSInterp_INCLUDE_DIRS};${XMSCore_INCLUDE_DIRS};${XMSGrid_INCLUDE_DIRS};${Boost_INCLUDE_DIRS})
  list(APPEND EXT_LIB_DIRS ${XMSInterp_LIBRARY_DIRS};${XMSCore_LIBRARY_DIRS};${XMSGrid_LIBRARY_DIRS};${Boost_LIBRARY_DIRS})
  list(APPEND EXT_LIBS ${XMSInterp_LIBRARIES};${XMSCore_LIBRARIES};${XMSGrid_LIBRARIES};${Boost_LIBRARIES};z)
else() # If we are not using conda, we are using conan
  # Conan setup
  include(${CMAKE_BINARY_DIR}/conanbuildinfo.cmake)
  conan_basic_setup(TARGETS)
  list(APPEND EXT_INCLUDE_DIRS ${CONAN_INCLUDE_DIRS})
  list(APPEND EXT_LIB_DIRS ${CONAN_LIB_DIRS})
  list(APPEND EXT_LIBS ${CONAN_LIBS})
endif()

if(WIN32)
    string(COMPARE EQUAL "${CONAN_SETTINGS_COMPILER_RUNTIME}" "MT" USES_MT)
    if(NOT USES_MT)
        string(COMPARE EQUAL "${CONAN_SETTINGS_COMPILER_RUNTIME}" "MTd" USES_MT)
    endif()

    if(USES_MT)
        message("Treating wchar_t as a built-in type.")
        add_definitions(/Zc:wchar_t)  # Treat wchar_t as built-in type
    else()
        message("Treating wchar_t as a typedef.")
        add_definitions(/Zc:wchar_t-)  # Treat wchar_t as typedef
    endif()

    if(XMS_BUILD)
        add_definitions(/D _WIN32_WINNT=0x0501)  # Windows XP and higher
    else(NOT XMS_BUILD)
        add_definitions(/D BOOST_ALL_NO_LIB)
    endif()
endif()

if(ENABLE_PYTHON)
    # Pybind11 module
    if(XMS_BUILD_MODE STREQUAL "CONDA")
        include("${CONDA_PREFIX}/share/cmake/pybind11/pybind11Targets.cmake")
        include("${CONDA_PREFIX}/share/cmake/pybind11/FindPythonLibsNew.cmake")
        include("${CONDA_PREFIX}/share/cmake/pybind11/pybind11Config.cmake")
        include("${CONDA_PREFIX}/share/cmake/pybind11/pybind11ConfigVersion.cmake")
        include("${CONDA_PREFIX}/share/cmake/pybind11/pybind11Tools.cmake")
    elseif(XMS_BUILD_MODE STREQUAL "CONAN")
        include("${CONAN_PYBIND11_ROOT}/share/cmake/pybind11/pybind11Targets.cmake")
        include("${CONAN_PYBIND11_ROOT}/share/cmake/pybind11/FindPythonLibsNew.cmake")
        include("${CONAN_PYBIND11_ROOT}/share/cmake/pybind11/pybind11Config.cmake")
        include("${CONAN_PYBIND11_ROOT}/share/cmake/pybind11/pybind11ConfigVersion.cmake")
        include("${CONAN_PYBIND11_ROOT}/share/cmake/pybind11/pybind11Tools.cmake")
    else()
        find_package(pybind11 CONFIG REQUIRED)
    endif()

    list(APPEND EXT_INCLUDE_DIRS
        ${pybind11_INCLUDE_DIR}
    )

    find_package(PythonLibsNew ${PYTHON_TARGET_VERSION} EXACT REQUIRED)

    message("PYTHON_INCLUDE: ${PYTHON_INCLUDE_DIRS}")
    message("PYTHON_LIBS: ${PYTHON_LIBRARIES}")

    list(APPEND EXT_INCLUDE_DIRS
      ${PYTHON_INCLUDE_DIRS}
    )
endif()

include_directories(${CMAKE_CURRENT_LIST_DIR})
include_directories(${EXT_INCLUDE_DIRS})
link_directories(${EXT_LIB_DIRS})

# Static library sources
set(xmsmesh_sources
  xmsmesher/meshing/MeMeshUtils.cpp
  xmsmesher/meshing/MeMultiPolyTo2dm.cpp
  xmsmesher/meshing/MeMultiPolyMesher.cpp
  xmsmesher/meshing/detail/MeBadQuadRemover.cpp
  xmsmesher/meshing/detail/MeIntersectPolys.cpp
  xmsmesher/meshing/detail/MePointConnectionFixer.cpp
  xmsmesher/meshing/detail/MePolyPatcher.cpp
  xmsmesher/meshing/detail/MePolyOffsetter.cpp
  xmsmesher/meshing/detail/MePolyPaverToMeshPts.cpp
  xmsmesher/meshing/detail/MePolyCleaner.cpp
  xmsmesher/meshing/detail/MePolyPts.cpp
  xmsmesher/meshing/detail/MePolyRedistributePtsCurvature.cpp
  xmsmesher/meshing/detail/MeQuadBlossom.cpp
  xmsmesher/meshing/detail/MeRefinePtsToPolys.cpp
  xmsmesher/meshing/detail/MeRelaxer.cpp
  xmsmesher/meshing/detail/MeWeightMatcher.cpp
  xmsmesher/meshing/MePolyMesher.cpp
  xmsmesher/meshing/MePolyRedistributePts.cpp
  xmsmesher/tutorial/TutMeshing.cpp)

set(xmsmesh_headers
  xmsmesher/meshing/MeMeshUtils.h
  xmsmesher/meshing/MePolyMesher.h
  xmsmesher/meshing/MeMultiPolyMesher.h
  xmsmesher/meshing/MeMultiPolyMesherIo.h
  xmsmesher/meshing/MeMultiPolyTo2dm.h
  xmsmesher/meshing/MePolyRedistributePts.h
  xmsmesher/meshing/detail/MeBadQuadRemover.h
  xmsmesher/meshing/detail/MePolyCleaner.h
  xmsmesher/meshing/detail/MePolyOffsetter.h
  xmsmesher/meshing/detail/MePolyPts.h
  xmsmesher/meshing/detail/MePolyPatcher.h
  xmsmesher/meshing/detail/MeIntersectPolys.h
  xmsmesher/meshing/detail/MePointConnectionFixer.h
  xmsmesher/meshing/detail/MePolyPaverToMeshPts.h
  xmsmesher/meshing/detail/MePolyRedistributePtsCurvature.h
  xmsmesher/meshing/detail/MeQuadBlossom.h
  xmsmesher/meshing/detail/MeRefinePtsToPolys.h
  xmsmesher/meshing/detail/MeRelaxer.h
  xmsmesher/meshing/detail/MeWeightMatcher.h)

# Pybind11 sources
set(xmsmesh_py_source
  xmsmesher/python/xmsmesher_py.cpp
  # Meshing
  xmsmesher/python/meshing/meshing_py.cpp
  xmsmesher/python/meshing/MeMeshUtils_py.cpp
  xmsmesher/python/meshing/MeMultiPolyMesherIo_py.cpp
  xmsmesher/python/meshing/MePolyRedistributePts_py.cpp
)

set(xmsmesh_py_headers
  xmsmesher/python/meshing/meshing_py.h
)

# Tests
if (BUILD_TESTING)
  add_definitions(-DXMS_TEST_PATH="${XMS_TEST_PATH}/")
  add_definitions(-DCXX_TEST)

  list(APPEND xmsmesh_sources
    xmsmesher/meshing/MeMeshUtils.t.h
    xmsmesher/meshing/MeMultiPolyTo2dm.t.h
    xmsmesher/meshing/MePolyMesher.t.h
    xmsmesher/meshing/MeMultiPolyMesher.t.h
    xmsmesher/meshing/MePolyRedistributePts.t.h
    xmsmesher/meshing/detail/MeBadQuadRemover.t.h
    xmsmesher/meshing/detail/MePolyPaverToMeshPts.t.h
    xmsmesher/meshing/detail/MeIntersectPolys.t.h
    xmsmesher/meshing/detail/MePointConnectionFixer.t.h
    xmsmesher/meshing/detail/MePolyPatcher.t.h
    xmsmesher/meshing/detail/MePolyOffsetter.t.h
    xmsmesher/meshing/detail/MePolyCleaner.t.h
    xmsmesher/meshing/detail/MePolyRedistributePtsCurvature.t.h
    xmsmesher/meshing/detail/MeQuadBlossom.t.h
    xmsmesher/meshing/detail/MeRefinePtsToPolys.t.h
    xmsmesher/meshing/detail/MeRelaxer.t.h
    xmsmesher/meshing/detail/MeWeightMatcher.t.h
    xmsmesher/testing/TestTools.cpp
    xmsmesher/testing/TestTools.h
    xmsmesher/tutorial/TutMeshing.t.h
  )

  find_package(CxxTest)
  if(CXXTEST_FOUND)
    include_directories(${CXXTEST_INCLUDE_DIRS})
    enable_testing()

    set(CXXTEST_TESTGEN_ARGS --xunit-printer --have-eh)
    file(GLOB_RECURSE test_headers ${CMAKE_CURRENT_LIST_DIR}/xmsmesher/*.t.h)
    CXXTEST_ADD_TEST(
      runner runner.cpp ${test_headers}
    )
    target_link_libraries(runner ${PROJECT_NAME})
  endif()
endif ()

# Static library
add_library(${PROJECT_NAME}
  ${xmsmesh_sources} ${xmsmesh_headers}
)
set_property(TARGET ${PROJECT_NAME} PROPERTY EXPORT_NAME Mesher)
target_include_directories(${PROJECT_NAME}
  PUBLIC
    $<BUILD_INTERFACE:${CMAKE_SOURCE_DIR}>
    $<INSTALL_INTERFACE:include/>
    ${Boost_INCLUDE_DIR}
 )
find_package(Threads REQUIRED)
target_link_libraries(${PROJECT_NAME}
  ${EXT_LIBS}
)
target_link_libraries(${PROJECT_NAME}
  ${CMAKE_THREAD_LIBS_INIT}
)
if(UNIX AND NOT APPLE)
    target_link_libraries(${PROJECT_NAME} rt)
endif()

if(ENABLE_PYTHON)
    pybind11_add_module(_xmsmesher
      ${xmsmesh_py_source} ${xmsmesh_py_headers}
    )

    target_include_directories(_xmsmesher
        PRIVATE
          ${EXT_LIB_DIRS}
          ${PYTHON_INCLUDE_DIRS}
    )
    target_link_libraries(_xmsmesher
      PRIVATE
        ${EXT_LIBS}
        ${PROJECT_NAME}
    )
    set_target_properties(_xmsmesher PROPERTIES
      LINKER_LANGUAGE CXX
    )

    if (XMS_BUILD_MODE STREQUAL "CMAKE")
      # Using a standard installation heirarchy for python packages
      set(XMS_PYTHON_INSTALL_PREFIX "${CMAKE_INSTALL_LIBDIR}/python-${PYTHON_TARGET_VERSION}/site-packages")
      # Skip installing setup.py
      set(XMS_PYTHON_INSTALL_PACKAGE_EXTRA
        PATTERN "setup.py" EXCLUDE)
    else ()
      set(XMS_PYTHON_INSTALL_PREFIX "_package")
    endif ()
    # Install recipe
    install(
      TARGETS _xmsmesher
      ARCHIVE DESTINATION "${XMS_PYTHON_INSTALL_PREFIX}/xms/mesher"
      LIBRARY DESTINATION "${XMS_PYTHON_INSTALL_PREFIX}/xms/mesher"
    )

    install(
      DIRECTORY "_package/"
      DESTINATION "${XMS_PYTHON_INSTALL_PREFIX}"
      FILES_MATCHING PATTERN "*.py"
      PATTERN "_package/tests" EXCLUDE
      ${XMS_PYTHON_INSTALL_PACKAGE_EXTRA})
endif()

# Disable Optimization for GCC6 for now... Report issue to gcc and pybind
if("${CMAKE_CXX_COMPILER_ID}" STREQUAL "GNU" AND ENABLE_PYTHON)
  if(CMAKE_CXX_COMPILER_VERSION VERSION_GREATER_EQUAL 6 AND CMAKE_CXX_COMPILER_VERSION VERSION_LESS 7)
    Message("Disabling Optimization for GCC 6...")
    STRING(REPLACE "-O3" "" CMAKE_CXX_FLAGS_RELEASE ${CMAKE_CXX_FLAGS_RELEASE})
    STRING(REPLACE "-O3" "" CMAKE_C_FLAGS_RELEASE ${CMAKE_C_FLAGS_RELEASE})
  endif()
endif()


# Install recipe
install(
  TARGETS ${PROJECT_NAME}
  EXPORT ${PROJECT_NAME}
  ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
  LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
  RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
  INCLUDES DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}
)
foreach (header IN LISTS xmsmesh_headers xmsmesh_py_headers)
  get_filename_component(subdir "${header}" DIRECTORY)
  install(
    FILES "${header}"
    DESTINATION "include/${subdir}"
  )
endforeach ()

# Install the CMake configs
install(
  EXPORT ${PROJECT_NAME}
  FILE xmsmesher-targets.cmake
  NAMESPACE XMS::
  DESTINATION "${CMAKE_INSTALL_LIBDIR}/cmake/xms")

install(
  FILES CMake/xmsmesher-config.cmake
  DESTINATION "${CMAKE_INSTALL_LIBDIR}/cmake/xms")
