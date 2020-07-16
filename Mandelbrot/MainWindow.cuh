#pragma once

#include <complex>
#include <functional>

#include <SDL.h>
#include "Window.hpp"

typedef std::complex<double> fComplex64;
typedef std::function<fComplex64(fComplex64, fComplex64)> FractalSequence;

constexpr uint16_t WIDTH = 1000;
constexpr uint16_t HEIGHT = 800;


class MainWindow: public sf::IWindow
{
public:
	MainWindow();
	~MainWindow() = default;

	void SetFunction(FractalSequence func);

private:
	bool OnCreate() override;
	bool OnUpdate(double frametime) override;
	void OnRender(SDL_Renderer* renderer) override;
	void OnClose() override;

	fComplex64 MapComplex(const fComplex64& value, const SDL_Rect& from, const SDL_Rect& to);
	fComplex64 MapComplex(const fComplex64& value, const fComplex64& centerPoint, double pixelSize);

	bool GetMandelbrotColors(Uint32** pixels);

private:
	FractalSequence pFunction;

	Uint32* cuda_screen = nullptr;
	Uint32* cuda_colors = nullptr;

	double xInterval = 3.f;

	Uint32* pPixels = nullptr;

	SDL_Texture* pRender;
};
