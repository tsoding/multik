#include <SDL2/SDL.h>
#include <caml/mlvalues.h>
#include <stdio.h>

static SDL_Window *window = NULL;
static SDL_Renderer *renderer = NULL;

CAMLprim value
console_init(value width, value height)
{
    SDL_Init(SDL_INIT_EVERYTHING);
    if (window == NULL) {
        window = SDL_CreateWindow(
            "Multik",
            100, 100,
            Int_val(width), Int_val(height),
            SDL_WINDOW_SHOWN | SDL_WINDOW_RESIZABLE);
        if (window == NULL) {
            /* TODO: multik.c does not raise an error when failed to create an SDL window */
            return Val_unit;
        }
    }

    if (renderer == NULL) {
        renderer = SDL_CreateRenderer(
            window, -1,
            SDL_RENDERER_ACCELERATED | SDL_RENDERER_PRESENTVSYNC);
        if (renderer == NULL) {
            /* TODO: multik.c does not raise an error when failed to create an SDL renderer */
            return Val_unit;
        }
    }
}

CAMLprim value
console_should_quit(value unit)
{
    SDL_Event event;
    while (SDL_PollEvent(&event)) {
        switch (event.type) {
        case SDL_QUIT:
            return Val_true;
        }
    }

    return Val_false;
}

CAMLprim value
console_render(value unit)
{
    SDL_SetRenderDrawColor(renderer, 255, 0, 0, 255);
    SDL_RenderClear(renderer);
    SDL_RenderPresent(renderer);

    return Val_unit;
}

CAMLprim value
console_free(value unit)
{
    if (renderer != NULL) {
        SDL_DestroyRenderer(renderer);
        renderer = NULL;
    }

    if (window != NULL) {
        SDL_DestroyWindow(window);
        window = NULL;
    }

    SDL_Quit();

    return Val_unit;
}
