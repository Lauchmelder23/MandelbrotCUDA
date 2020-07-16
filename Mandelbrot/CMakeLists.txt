# CMakeList.txt : CMake project for Mandelbrot, include source and define
# project specific logic here.
#
cmake_minimum_required (VERSION 3.8)

set(CMAKE_CUDA_FLAGS "${CMAKE_CUDA_FLAGS} --expt-relaxed-constexpr")

# Add source to this project's executable.
add_executable (Mandelbrot  "main.cu" 
	"MainWindow.cu"
)

# TODO: Add tests and install targets if needed.
target_include_directories(Mandelbrot PRIVATE
	${SDL2_INCLUDE_DIRS}
	${CMAKE_CUDA_TOOLKIT_INCLUDE_DIRECTORIES}
	${CMAKE_SOURCE_DIR}/SDLFramework/src/sdlf
)

target_link_libraries(Mandelbrot PRIVATE
	${SDL2_LIBRARIES}
	sdlf
)

if(WIN32)
	add_custom_command(TARGET Mandelbrot POST_BUILD
		COMMAND ${CMAKE_COMMAND} -E copy ${SDL2_DLL} $<TARGET_FILE_DIR:Mandelbrot>
	)
endif(WIN32)