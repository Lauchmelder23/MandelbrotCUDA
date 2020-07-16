#include <complex>

#include "MainWindow.cuh"

fComplex64 func(fComplex64 z, fComplex64 c)
{
	return z * z + c;
}

int main(int argc, char** argv)
{
	SDL_Init(SDL_INIT_VIDEO);

	MainWindow window;
	window.SetFunction(func);

	window.Launch(false);
	window.Stop();

	return 0;
}