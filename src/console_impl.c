#include <SDL2/SDL.h>
#include <caml/mlvalues.h>
#include <stdio.h>

static SDL_Window *window = NULL;
static SDL_Renderer *renderer = NULL;

CAMLprim value
console_init(value width, value height)
{
    if (SDL_Init(SDL_INIT_EVERYTHING) < 0) {
        goto fail;
    }

    if (window == NULL) {
        window = SDL_CreateWindow(
            "Multik",
            100, 100,
            Int_val(width), Int_val(height),
            SDL_WINDOW_SHOWN | SDL_WINDOW_RESIZABLE);
        if (window == NULL) {
            goto fail;
        }
    }

    if (renderer == NULL) {
        renderer = SDL_CreateRenderer(
            window, -1,
            SDL_RENDERER_ACCELERATED | SDL_RENDERER_PRESENTVSYNC);
        if (renderer == NULL) {
            goto fail;
        }
    }

    return Val_unit;

fail:
    if (renderer != NULL) {
        renderer = NULL;
        SDL_DestroyRenderer(renderer);
    }

    if (window != NULL) {
        window = NULL;
        SDL_DestroyWindow(window);
    }

    caml_failwith(SDL_GetError());
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
    if (renderer == NULL) {
        caml_failwith("Renderer is not initialized");
    }

    if (SDL_SetRenderDrawColor(renderer, 255, 0, 0, 255) < 0) {
        caml_failwith(SDL_GetError());
    }

    if (SDL_RenderClear(renderer) < 0) {
        caml_failwith(SDL_GetError());
    }

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
