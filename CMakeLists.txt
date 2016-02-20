cmake_minimum_required(VERSION 3.4)

project(boost_path)

# Force all libraries and exes to be built to the top-level build dir.
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR})
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR})
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR})

# options
option(USE_BOOST_CACHE "If ON, try to download, extract and build boost to a single cache directory" OFF)
if(APPLE)
  option(HAVE_LIBC++ "If ON, '-stdlib=libc++' is added to the compile and link flags" ON)
else()
  option(HAVE_LIBC++ "If ON, '-stdlib=libc++' is added to the compile and link flags" OFF)
  option(HAVE_LIBC++ABI "If ON, '-lc++abi' is added to the link flags" OFF)
endif()

set(CMAKE_MODULE_PATH ${boost_path_SOURCE_DIR}/cmake)
include(Flags)
include(Utils)

if(MSVC AND NOT MSVC14)
	set(BoostVersion 1.58.0)
	set(BoostComponents system locale filesystem)
	include(AddBoost)

	message(STATUS "Boost include path: " ${Boost_INCLUDE_DIRS})
	message(STATUS "Boost libs: " )
	foreach(BoostLib ${AllBoostLibs})
		message(STATUS " + ${BoostLib}" )
	endforeach()
endif()

set(SOURCE_FILES main.cpp)
add_executable(boost_path ${SOURCE_FILES})

# options for all project (boost bjam ignore it)
if(MSVC)
	add_definitions(-D_CRT_SECURE_NO_DEPRECATE)
	add_definitions(-DBOOST_ALL_NO_LIB)
	add_definitions(-DBOOST_ALL_DYN_LINK)
	add_definitions(-DUNICODE -D_UNICODE -U_MBCS -UMBCS)
	remove_definitions(-D_MBCS -DMBCS -DSBCS -D_SBCS)

	if(NOT MSVC14)
		target_include_directories(boost_path PRIVATE ${Boost_INCLUDE_DIRS})
		target_link_libraries(boost_path PRIVATE BoostFilesystem BoostLocale BoostSystem)

		add_custom_command(TARGET boost_path POST_BUILD	
			COMMAND ${CMAKE_COMMAND} -E copy_if_different $<TARGET_FILE:BoostFilesystem> $<TARGET_FILE_DIR:boost_path>
			COMMAND ${CMAKE_COMMAND} -E copy_if_different $<TARGET_FILE:BoostLocale> $<TARGET_FILE_DIR:boost_path>	
			COMMAND ${CMAKE_COMMAND} -E copy_if_different $<TARGET_FILE:BoostSystem> $<TARGET_FILE_DIR:boost_path>	
		)
	endif()
else()
  find_package(Boost COMPONENTS system locale filesystem REQUIRED)

  if(Boost_FOUND)
      message(STATUS "Boost Libraries: ${Boost_LIBRARIES}")
      add_compile_options(-std=c++14 -Wno-deprecated-declarations)
      target_include_directories(boost_path PRIVATE ${Boost_INCLUDE_DIRS})
      target_link_libraries(boost_path PRIVATE ${Boost_FILESYSTEM_LIBRARY} ${Boost_SYSTEM_LIBRARY} ${Boost_LOCALE_LIBRARY})
  endif()
endif()

