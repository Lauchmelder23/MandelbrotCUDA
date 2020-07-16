#include "MainWindow.cuh"
#include <iostream>
#include <string>

#define WIN32_LEAN_AND_MEAN

#include <Windows.h>

#include <cuda_runtime.h>
#include <device_launch_parameters.h>

#define CHECK_CUDA_ERROR(error, msg) {											\
	if(error != cudaSuccess) {													\
		std::cerr << msg << std::endl << cudaGetErrorString(error) << std::endl;\
		return false;															\
	}																			\
}

__global__ void PopulateArrayWithIndexed(uint32_t* out, int n)
{
	int index = blockIdx.x * blockDim.x + threadIdx.x;

	if(index < n)
		out[index] = ((uint32_t)(index % WIDTH) << 16 | (uint32_t)(index / WIDTH));
}

__global__ void Mandelbrot(uint32_t* in, uint32_t* out, 
	double centerX, double centerY, 
	double cmplxCenterX, double cmplxCenterY, 
	double pixelSize, 
	int maxIteration, int maxValue,
	int n)
{
	int index = blockIdx.x * blockDim.x + threadIdx.x;
	int stride = 1;

	double x, cx;
	double y, cy;
	double tempX;

	if(index < n)
	{
		x = 0;
		y = 0;

		cx = (((in[index] & 0xFFFF0000) >> 16) - centerX) * pixelSize + cmplxCenterX;
		cy = (((in[index] & 0x0000FFFF) >> 0) - centerY) * pixelSize - cmplxCenterY;

		for (uint32_t j = 0; j < maxIteration; j++)
		{
			tempX = x * x - y * y + cx;
			y = 2 * x * y + cy;
			x = tempX;

			if (x * x + y * y >= maxValue)
			{
				out[index] = 0xFFFFFFFF;
				return;
			}
		}

		out[index] = 0x000000FF;
	}
}


MainWindow::MainWindow() :
	sf::IWindow(sf::Vector2u(1000, 800), 
		sf::UnitVector2i * SDL_WINDOWPOS_UNDEFINED,
		"Mandelbrot"),
	pRender(nullptr)
{

}

void MainWindow::SetFunction(FractalSequence func)
{
	pFunction = func;
}

bool MainWindow::OnCreate()
{
	pRender = SDL_CreateTexture(m_pRenderer, 
		SDL_PIXELFORMAT_RGBA8888, SDL_TEXTUREACCESS_STREAMING, 
		WIDTH, HEIGHT
	);
	if (pRender == nullptr)
	{
		std::cerr << "Failed to initialize Render Texture: " << SDL_GetError() << std::endl;
		return false;
	}

	SDL_SetRenderDrawColor(m_pRenderer, 0, 0, 0, 255);

	return true;
}

bool MainWindow::GetMandelbrotColors(Uint32** pixels)
{
	constexpr int ARR_SIZE = WIDTH * HEIGHT;

	// Calculate / set thread/block size
	constexpr int threadsPerBlock = 256;
	constexpr int blocksPerGrid = (ARR_SIZE + threadsPerBlock - 1) / threadsPerBlock;

	cudaError_t err;

	// Create device memory for screen indices
	if (cuda_screen == NULL)
	{
		err = cudaMalloc((void**)&cuda_screen, ARR_SIZE * sizeof(uint32_t));
		CHECK_CUDA_ERROR(err, "Failed to create array on device");

		// Call device kernel to fill array
		PopulateArrayWithIndexed<<<blocksPerGrid, threadsPerBlock>>>(cuda_screen, ARR_SIZE);
		err = cudaGetLastError();
		CHECK_CUDA_ERROR(err, "Failed to launch kernel: ");
	}

	// Create device memory for color data;
	if (cuda_colors == NULL)
	{
		err = cudaMalloc((void**)&cuda_colors, ARR_SIZE * sizeof(uint32_t));
		CHECK_CUDA_ERROR(err, "Failed to create array on device");
	}

	// Call device kernel to calculate mandelbrot colors for each pixel
	Mandelbrot<<<blocksPerGrid, threadsPerBlock>>>(cuda_screen, cuda_colors,
		WIDTH / 2, HEIGHT / 2,
		-0.77568377f, 0.13646737,
		xInterval / WIDTH,
		1000, 100000,
		ARR_SIZE);
	err = cudaGetLastError();
	CHECK_CUDA_ERROR(err, "Failed to launch kernel: ");

	// Free given memory to avoid memory leaks
	if (*pixels == nullptr)
	{
		*pixels = (Uint32*)malloc(ARR_SIZE * sizeof(Uint32));
	}

	err = cudaMemcpy(*pixels, cuda_colors, ARR_SIZE * sizeof(Uint32), cudaMemcpyDeviceToHost);
	CHECK_CUDA_ERROR(err, "Failed to memcpy from device to host");

	return true;
}

bool MainWindow::OnUpdate(double frametime)
{
	SDL_SetWindowTitle(m_pWindow, (std::to_string(1.f / frametime) + std::string(" FPS")).c_str());

	static int pitch = 0;
	SDL_LockTexture(pRender, NULL, (void**)&pPixels, &pitch);

	if (!GetMandelbrotColors(&pPixels))
	{
		SDL_UnlockTexture(pRender);
		return false;
	}

	SDL_UnlockTexture(pRender);

	xInterval -= frametime * xInterval * 0.5;

	return true;
}

void MainWindow::OnRender(SDL_Renderer* renderer)
{
	SDL_RenderClear(m_pRenderer);
	SDL_RenderCopy(m_pRenderer, pRender, NULL, NULL);
}

void MainWindow::OnClose()
{
	//SDL_DestroyTexture(pRender);
	
	//free(pPixels);
	
	//cudaError_t err;

	// Free device memory for color data
	// err = cudaFree(cuda_colors);

	// Free device memory for screen indices
	// err = cudaFree((void*)cuda_screen);
}

fComplex64 MainWindow::MapComplex(const fComplex64& value, const SDL_Rect& from, const SDL_Rect& to)
{
	fComplex64 ret(
		(value.real() - from.x) * (to.w - to.x) / (from.w - from.x) + to.x,
		(value.imag() - from.y) * (to.h - to.y) / (from.h - from.y) + to.y
	);
	return ret;
}

fComplex64 MainWindow::MapComplex(const fComplex64& value, const fComplex64& centerPoint, double pixelSize)
{
	return ((value - centerPoint) * pixelSize);
}
