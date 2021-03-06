﻿# CMakeList.txt : Top-level CMake project file, do global configuration
# and include sub-projects here.
#
cmake_minimum_required (VERSION 3.8)

project ("Mandelbrot")
enable_language(CUDA)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR})

set(THREADS_PREFER_PTHREAD_FLAG ON)


if(WIN32)
	set(SDL2_INCLUDE_DIRS ${CMAKE_SOURCE_DIR}/SDLFramework/3rdparty/include/SDL)
	set(SDL2_LIBRARIES 
		${CMAKE_SOURCE_DIR}/SDLFramework/3rdparty/lib/SDL2.lib 
		${CMAKE_SOURCE_DIR}/SDLFramework/3rdparty/lib/SDL2main.lib
	)
	set(SDL2_DLL
		${CMAKE_SOURCE_DIR}/SDLFramework/3rdparty/lib/SDL2.dll
	)
else()
	find_package(SDL2 REQUIRED)

	SET(CMAKE_CXX_FLAGS -pthread)
endif(WIN32)

# Include sub-projects.
add_subdirectory ("SDLFramework")
add_subdirectory ("Mandelbrot")
