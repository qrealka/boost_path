#==================================================================================================#
#                                                                                                  #
#  Sets up Boost using ExternalProject_Add.                                                        #
#                                                                                                  #
#  Only the first 2 variables should require regular maintenance, i.e. BoostVersion & BoostSHA1.   #
#                                                                                                  #
#  If USE_BOOST_CACHE is set, boost is downloaded, extracted and built to a directory outside of   #
#  the build tree.  The chosen directory can be set in BOOST_CACHE_DIR, or if this is empty,       #
#  an appropriate default is chosen for the given platform.                                        #
#                                                                                                  #
#  Variables set and cached by this module are:                                                    #
#    BoostSourceDir (required for subsequent include_directories calls) and per-library            #
#    variables defining the libraries, e.g. BoostDateTimeLibs, BoostFilesystemLibs.                #
#                                                                                                  #
#==================================================================================================#


# Create build folder name derived from version
string(REGEX REPLACE "beta\\.([0-9])$" "beta\\1" BoostFolderName ${BoostVersion})
string(REPLACE "." "_" BoostFolderName ${BoostFolderName})
set(BoostFolderName boost_${BoostFolderName})

# If user wants to use a cache copy of Boost, get the path to this location.
if(USE_BOOST_CACHE)
  if(BOOST_CACHE_DIR)
    file(TO_CMAKE_PATH "${BOOST_CACHE_DIR}" BoostCacheDir)
  elseif(WIN32)
    get_temp_dir()
    set(BoostCacheDir "${TempDir}")
  elseif(APPLE)
    set(BoostCacheDir "$ENV{HOME}/Library/Caches")
  else()
    set(BoostCacheDir "$ENV{HOME}/.cache")
  endif()
endif()

# If the cache directory doesn't exist, fall back to use the build root.
if(NOT IS_DIRECTORY "${BoostCacheDir}")
  if(BOOST_CACHE_DIR)
    set(Message "\nThe directory \"${BOOST_CACHE_DIR}\" provided in BOOST_CACHE_DIR doesn't exist.")
    set(Message "${Message}  Falling back to default path at \"${CMAKE_BINARY_DIR}/Nitro\"\n")
    message(WARNING "${Message}")
  endif()
  set(BoostCacheDir ${CMAKE_BINARY_DIR})
else()
  if(NOT USE_BOOST_CACHE AND NOT BOOST_CACHE_DIR)
    set(BoostCacheDir "${BoostCacheDir}/Nitro")
  endif()
  file(MAKE_DIRECTORY "${BoostCacheDir}")
endif()

# Set up the full path to the source directory
set(BoostSourceDir "${BoostFolderName}_${CMAKE_CXX_COMPILER_ID}_${CMAKE_CXX_COMPILER_VERSION}")
if(HAVE_LIBC++)
  set(BoostSourceDir "${BoostSourceDir}_LibCXX")
endif()
if(HAVE_LIBC++ABI)
  set(BoostSourceDir "${BoostSourceDir}_LibCXXABI")
endif()
if(CMAKE_CL_64)
  set(BoostSourceDir "${BoostSourceDir}_Win64")
endif()
string(REPLACE "." "_" BoostSourceDir ${BoostSourceDir})
set(BoostSourceDir "${BoostCacheDir}/${BoostSourceDir}")

# Check the full path to the source directory is not too long for Windows.  File paths must be less
# than MAX_PATH which is 260.  The current longest relative path Boost tries to create is:
# Build\boost\bin.v2\libs\program_options\build\fd41f4c7d882e24faa6837508d6e5384\libboost_program_options-vc120-mt-gd-1_55.lib.rsp
# which along with a leading separator is 129 chars in length.  This gives a maximum path available
# for 'BoostSourceDir' as 130 chars.
if(WIN32)
  get_filename_component(BoostSourceDirName "${BoostSourceDir}" NAME)
  string(LENGTH "/${BoostSourceDirName}" BoostSourceDirNameLengthWithSeparator)
  math(EXPR AvailableLength 130-${BoostSourceDirNameLengthWithSeparator})
  string(LENGTH "${BoostSourceDir}" BoostSourceDirLength)
  if(BoostSourceDirLength GREATER "130")
    set(Msg "\n\nThe path to boost's source is too long to handle all the files which will ")
    set(Msg "${Msg}be created when boost is built.  To avoid this, set the CMake variable ")
    set(Msg "${Msg}USE_BOOST_CACHE to ON and set the variable BOOST_CACHE_DIR to a path ")
    set(Msg "${Msg}which is at most ${AvailableLength} characters long.  For example:\n")
    set(Msg "${Msg}  mkdir C:\\tmp_boost\n")
    set(Msg "${Msg}  cmake . -DUSE_BOOST_CACHE=ON -DBOOST_CACHE_DIR=C:\\tmp_boost\n\n")
    message(FATAL_ERROR "${Msg}")
  endif()
endif()

# Download boost if required
set(ZipFilePath "${BoostCacheDir}/${BoostFolderName}.tar.bz2")
set(Found 0)  
if(NOT EXISTS ${ZipFilePath})
  message(STATUS "Downloading boost ${BoostVersion} to ${BoostCacheDir}")
  file(DOWNLOAD http://sourceforge.net/projects/boost/files/boost/${BoostVersion}/${BoostFolderName}.tar.bz2/download
     ${ZipFilePath}
     STATUS Status
  )
  string(FIND "${Status}" "returning early" Found)
else()
  message(STATUS "Boost archive already exists ${ZipFilePath}")  
endif()

# Extract boost if required
if(Found LESS "0" OR NOT IS_DIRECTORY "${BoostSourceDir}" OR NOT EXISTS "${BoostSourceDir}/boost/version.hpp")
  set(BoostExtractFolder "${BoostCacheDir}/boost_unzip")
  file(REMOVE_RECURSE ${BoostExtractFolder})
  file(MAKE_DIRECTORY ${BoostExtractFolder})
  file(COPY ${ZipFilePath} DESTINATION ${BoostExtractFolder})
  message(STATUS "Extracting boost ${BoostVersion} to ${BoostExtractFolder}")
  execute_process(COMMAND ${CMAKE_COMMAND} -E tar xfz ${BoostFolderName}.tar.bz2
                  WORKING_DIRECTORY ${BoostExtractFolder}
                  RESULT_VARIABLE Result
                  )
  if(NOT Result EQUAL "0")
    message(FATAL_ERROR "Failed extracting boost ${BoostVersion} to ${BoostExtractFolder}")
  endif()
  file(REMOVE ${BoostExtractFolder}/${BoostFolderName}.tar.bz2)

  # Get the path to the extracted folder
  file(GLOB ExtractedDir "${BoostExtractFolder}/*")
  list(LENGTH ExtractedDir n)
  if(NOT n EQUAL "1" OR NOT IS_DIRECTORY ${ExtractedDir})
    message(FATAL_ERROR "Failed extracting boost ${BoostVersion} to ${BoostExtractFolder}")
  endif()
  file(RENAME ${ExtractedDir} ${BoostSourceDir})
  file(REMOVE_RECURSE ${BoostExtractFolder})
else()  
  message(STATUS "Boost archive already extracted to ${BoostSourceDir}")  
endif()

# Build b2 (bjam) if required
unset(b2Path CACHE)
find_program(b2Path NAMES b2 PATHS ${BoostSourceDir} NO_DEFAULT_PATH)
if(NOT b2Path)
  message(STATUS "Building b2 (bjam)")
  if(MSVC)
    set(b2Bootstrap "bootstrap.bat")
  else()
    set(b2Bootstrap "./bootstrap.sh")
    if(CMAKE_CXX_COMPILER_ID MATCHES "^(Apple)?Clang$")
      list(APPEND b2Bootstrap --with-toolset=clang)
    elseif(CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
      list(APPEND b2Bootstrap --with-toolset=gcc)
    endif()
  endif()
  execute_process(COMMAND ${b2Bootstrap} WORKING_DIRECTORY ${BoostSourceDir}
                  RESULT_VARIABLE Result OUTPUT_VARIABLE Output ERROR_VARIABLE Error)
  if(NOT Result EQUAL "0")
    message(FATAL_ERROR "Failed running ${b2Bootstrap}:\n${Output}\n${Error}\n")
  endif()
endif()
execute_process(COMMAND ${CMAKE_COMMAND} -E make_directory ${BoostSourceDir}/Build)

# Expose BoostSourceDir to parent scope
set(BoostSourceDir ${BoostSourceDir}) #PARENT_SCOPE

# Set up general b2 (bjam) command line arguments
set(b2Args <SOURCE_DIR>/b2
           link=shared
           threading=multi
           runtime-link=shared
           --build-dir=Build
           stage
           -d+2
           --hash
           --ignore-site-config
           )
if(CMAKE_BUILD_TYPE STREQUAL "DebugLibStdcxx")
  list(APPEND b2Args define=_GLIBCXX_DEBUG)
endif()

# Set up platform-specific b2 (bjam) command line arguments
if(MSVC)
  if(MSVC11)
    list(APPEND b2Args toolset=msvc-11.0)
  elseif(MSVC12)
    list(APPEND b2Args toolset=msvc-12.0)
  elseif(MSVC14)
    list(APPEND b2Args toolset=msvc-14.0)
  endif()
  list(APPEND b2Args
			  variant=debug,release
			  define=UNICODE
			  define=_UNICODE
              define=_BIND_TO_CURRENT_MFC_VERSION=1
              define=_BIND_TO_CURRENT_CRT_VERSION=1
              --layout=versioned
              )
  if(TargetArchitecture STREQUAL "x86_64")
    list(APPEND b2Args address-model=64)
  endif()
elseif(APPLE)
  list(APPEND b2Args variant=debug,release toolset=clang cxxflags=-fPIC cxxflags=-std=c++11 cxxflags=-stdlib=libc++
                     linkflags=-stdlib=libc++ architecture=combined address-model=32,64 --layout=tagged)
elseif(UNIX)
  list(APPEND b2Args --layout=tagged -sNO_BZIP2=1)
    list(APPEND b2Args variant=debug,release cxxflags=-fPIC cxxflags=-std=c++11)
    # Need to configure the toolset based on CMAKE_CXX_COMPILER
    if(CMAKE_CXX_COMPILER_ID MATCHES "^(Apple)?Clang$")
      file(WRITE "${BoostSourceDir}/tools/build/src/user-config.jam" "using clang : : ${CMAKE_CXX_COMPILER} ;\n")
      list(APPEND b2Args toolset=clang)
      if(HAVE_LIBC++)
        list(APPEND b2Args cxxflags=-stdlib=libc++ linkflags=-stdlib=libc++)
      endif()
    elseif(CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
      file(WRITE "${BoostSourceDir}/tools/build/src/user-config.jam" "using gcc : : ${CMAKE_CXX_COMPILER} ;\n")
      list(APPEND b2Args toolset=gcc)
    endif()
endif()

set(Boost_INCLUDE_DIRS "${BoostSourceDir}")

# Build each required component
include(ExternalProject)
# BUILD_IN_SOURCE 1
foreach(Component ${BoostComponents})
  ExternalProject_Add(
      boost_${Component}
      PREFIX ${CMAKE_BINARY_DIR}/${BoostFolderName}
      SOURCE_DIR ${BoostSourceDir}
      BINARY_DIR ${BoostSourceDir}
      CONFIGURE_COMMAND ""
      BUILD_COMMAND "${b2Args}" --with-${Component}
      INSTALL_COMMAND "" 
      LOG_BUILD ON
      )
  underscores_to_camel_case(${Component} CamelCaseComponent)
  add_library(Boost${CamelCaseComponent} SHARED IMPORTED GLOBAL)
  if(Component STREQUAL "test")
    set(ComponentLibName unit_test_framework)
  else()
    set(ComponentLibName ${Component})
  endif()
  
  # https://cmake.org/Wiki/CMake/Tutorials/Exporting_and_Importing_Targets
  # for static link boost libraries has prefix 'libboost' for shared libraries 'boost'
  if(MSVC)
    if(MSVC11)
      set(CompilerName vc110)
    elseif(MSVC12)
      set(CompilerName vc120)
    elseif(MSVC14)
      set(CompilerName vc140)
    endif()
    string(REGEX MATCH "[0-9]_[0-9][0-9]" Version "${BoostFolderName}")
	
    set_target_properties(Boost${CamelCaseComponent} PROPERTIES
                          IMPORTED_LOCATION_DEBUG ${BoostSourceDir}/stage/lib/boost_${ComponentLibName}-${CompilerName}-mt-gd-${Version}.dll
                          IMPORTED_IMPLIB_DEBUG ${BoostSourceDir}/stage/lib/boost_${ComponentLibName}-${CompilerName}-mt-gd-${Version}.lib
                          IMPORTED_LOCATION_MINSIZEREL ${BoostSourceDir}/stage/lib/boost_${ComponentLibName}-${CompilerName}-mt-${Version}.dll
                          IMPORTED_IMPLIB_MINSIZEREL ${BoostSourceDir}/stage/lib/boost_${ComponentLibName}-${CompilerName}-mt-${Version}.lib
                          IMPORTED_LOCATION_RELEASE ${BoostSourceDir}/stage/lib/boost_${ComponentLibName}-${CompilerName}-mt-${Version}.dll
                          IMPORTED_IMPLIB_RELEASE ${BoostSourceDir}/stage/lib/boost_${ComponentLibName}-${CompilerName}-mt-${Version}.lib
                          IMPORTED_LOCATION_RELWITHDEBINFO ${BoostSourceDir}/stage/lib/boost_${ComponentLibName}-${CompilerName}-mt-${Version}.dll
                          IMPORTED_IMPLIB_RELWITHDEBINFO ${BoostSourceDir}/stage/lib/boost_${ComponentLibName}-${CompilerName}-mt-${Version}.dll
                          LINKER_LANGUAGE CXX)
  else()
    set_target_properties(Boost${CamelCaseComponent} PROPERTIES
                          IMPORTED_LOCATION ${BoostSourceDir}/stage/lib/boost_${ComponentLibName}-mt.so
                          LINKER_LANGUAGE CXX)
  endif()
  add_dependencies(Boost${CamelCaseComponent} boost_${Component})
  set(Boost${CamelCaseComponent}Libs Boost${CamelCaseComponent})
  
  if(Component STREQUAL "chrono" OR Component STREQUAL "filesystem")
	add_dependencies(boost_${Component} boost_system)
  endif()
  if(Component STREQUAL "locale")
    if(APPLE)
      find_library(IconvLib iconv)
      if(NOT IconvLib)
        message(FATAL_ERROR "libiconv.dylib must be installed to a standard location.")
      endif()
      set(Boost${CamelCaseComponent}Libs Boost${CamelCaseComponent} ${IconvLib})
    elseif(UNIX)
      if(BSD)
        find_library(IconvLib libiconv.a)
        if(NOT IconvLib)
          set(Msg "libiconv.a must be installed to a standard location.")
          set(Msg "  For ${Msg} on FreeBSD 10 or later, run\n  pkg install libiconv")
          message(FATAL_ERROR "${Msg}")
        endif()
        set(Boost${CamelCaseComponent}Libs Boost${CamelCaseComponent} ${IconvLib})
      elseif(NOT ANDROID_BUILD)
        find_library(Icui18nLib libicui18n.a)
        find_library(IcuucLib libicuuc.a)
        find_library(IcudataLib libicudata.a)
        if(NOT Icui18nLib OR NOT IcuucLib OR NOT IcudataLib)
          set(Msg "libicui18n.a, libicuuc.a & licudata.a must be installed to a standard location.")
          set(Msg "  For ${Msg} on Ubuntu/Debian, run\n  sudo apt-get install libicu-dev")
          message(FATAL_ERROR "${Msg}")
        endif()
        set(Boost${CamelCaseComponent}Libs Boost${CamelCaseComponent} ${Icui18nLib} ${IcuucLib} ${IcudataLib})
      endif()
    else()
      set(Boost${CamelCaseComponent}Libs Boost${CamelCaseComponent})
    endif()
    add_dependencies(boost_locale boost_system)
  endif()
  
  set(Boost${CamelCaseComponent}Libs ${Boost${CamelCaseComponent}Libs}) #PARENT_SCOPE
  list(APPEND AllBoostLibs Boost${CamelCaseComponent})
endforeach()

set(AllBoostLibs ${AllBoostLibs}) #PARENT_SCOPE
#add_dependencies(boost_log boost_chrono boost_date_time boost_filesystem boost_thread)
#add_dependencies(boost_thread boost_chrono)
#add_dependencies(boost_timer boost_chrono)
#add_dependencies(boost_wave boost_chrono boost_date_time boost_filesystem boost_thread)
