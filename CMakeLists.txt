cmake_minimum_required(VERSION 3.4)

project(boost_path)

# conan.io 
include(${CMAKE_BINARY_DIR}/conanbuildinfo.cmake)
CONAN_BASIC_SETUP()

# now boost can be used
set(Boost_USE_STATIC_LIBS OFF)
set(Boost_USE_MULTITHREADED ON)
set(Boost_USE_STATIC_RUNTIME OFF)
find_package(Boost REQUIRED system locale filesystem)

set(SOURCE_FILES main.cpp)

if(MSVC)
#  add_definitions(-DBOOST_ALL_NO_LIB)
#  add_definitions(-DBOOST_ALL_DYN_LINK)
else()
  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++11")
endif()

if(Boost_FOUND)
    include_directories(${Boost_INCLUDE_DIRS})
    add_executable(boost_path ${SOURCE_FILES})
#	message(STATUS "Link libraries: " ${Boost_LIBRARIES})
    target_link_libraries(boost_path PUBLIC ${Boost_LIBRARIES})
else()
    add_executable(boost_path ${SOURCE_FILES})
    target_link_libraries(boost_path PUBLIC ${CONAN_LIBS})
endif()