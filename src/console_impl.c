#include <stdio.h>

#include <caml/mlvalues.h>
#include <caml/fail.h>
#include <caml/alloc.h>
#include <caml/custom.h>
#include <caml/memory.h>

#include <SDL2/SDL.h>
#include <cairo.h>

static SDL_Window *window = NULL;
static SDL_Renderer *renderer = NULL;
static SDL_Texture *texture = NULL;

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

    if (SDL_SetRenderDrawBlendMode(renderer, SDL_BLENDMODE_BLEND) < 0) {
        goto fail;
    }

    if (texture == NULL) {
        texture = SDL_CreateTexture(
            renderer,
            SDL_PIXELFORMAT_ARGB8888,
            SDL_TEXTUREACCESS_STREAMING,
            Int_val(width), Int_val(height));
        if (texture == NULL) {
            goto fail;
        }
    }

    return Val_unit;

fail:
    if (texture != NULL) {
        SDL_DestroyTexture(texture);
        texture = NULL;
    }

    if (renderer != NULL) {
        SDL_DestroyRenderer(renderer);
        renderer = NULL;
    }

    if (window != NULL) {
        SDL_DestroyWindow(window);
        window = NULL;
    }

    failwith(SDL_GetError());

    return Val_unit;
}

CAMLprim value
console_should_quit(value unit)
{
    SDL_Event event;
    while (SDL_PollEvent(&event)) {
        switch (event.type) {
        case SDL_QUIT:
            return Val_true;

        case SDL_WINDOWEVENT:
            switch(event.window.event) {
            case SDL_WINDOWEVENT_RESIZED:
                if (renderer == NULL) {
                    caml_failwith("Renderer is not initialized");
                }

                if (texture == NULL) {
                    caml_failwith("Texture was not initialized");
                }

                SDL_DestroyTexture(texture);
                texture = SDL_CreateTexture(
                    renderer,
                    SDL_PIXELFORMAT_ARGB8888,
                    SDL_TEXTUREACCESS_STREAMING,
                    event.window.data1,
                    event.window.data2);
                break;
            }
            break;
        }
    }

    return Val_false;
}

CAMLprim value
console_present(value unit)
{
    if (renderer == NULL) {
        caml_failwith("Renderer is not initialized");
    }

    SDL_Rect view_port;
    SDL_RenderGetViewport(renderer, &view_port);
    SDL_RenderCopy(renderer, texture,
                   &view_port,
                   &view_port);

    SDL_RenderPresent(renderer);

    return Val_unit;
}

CAMLprim value
console_free(value unit)
{
    if (texture != NULL) {
        SDL_DestroyTexture(texture);
        texture = NULL;
    }

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

CAMLprim value
console_texture(value unit)
{
    return (value) texture;
}

CAMLprim value
console_viewport(value unit)
{
    CAMLparam1(unit);
    CAMLlocal1(result);

    result = caml_alloc(4, 0);

    if (renderer == NULL) {
        caml_failwith("Renderer is not initialized");
    }

    SDL_Rect view_port;
    SDL_RenderGetViewport(renderer, &view_port);

    Store_field(result, 0, caml_copy_double(view_port.x));
    Store_field(result, 1, caml_copy_double(view_port.y));
    Store_field(result, 2, caml_copy_double(view_port.w));
    Store_field(result, 3, caml_copy_double(view_port.h));

    CAMLreturn(result);
}
