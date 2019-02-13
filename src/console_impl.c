#include <stdio.h>

#include <caml/mlvalues.h>
#include <caml/fail.h>

#include <SDL2/SDL.h>
#include <cairo.h>

static SDL_Window *window = NULL;
static SDL_Renderer *renderer = NULL;
// TODO(#25): Is it possible to get rid of the SDL_Texture in console_impl?
//   And draw directly on renderer.
static SDL_Texture *texture = NULL;

static cairo_surface_t *cairo_surface = NULL;
static cairo_t *cairo_context = NULL;

static int reload = 0;

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
console_should_reload(value unit)
{
    int result = reload;
    reload = 0;
    return Val_bool(result);
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

        case SDL_KEYDOWN:
            reload = 1;
            break;
        }
    }

    return Val_false;
}

CAMLprim value
console_set_fill_color(value r, value g, value b, value a)
{
    if (cairo_context == NULL) {
        caml_failwith("Cairo Context is not initialized");
    }

    cairo_set_source_rgba(cairo_context, Double_val(r), Double_val(g), Double_val(b), Double_val(a));

    return Val_unit;
}

CAMLprim value
console_fill_rect(value x, value y, value w, value h)
{
    if (cairo_context == NULL) {
        caml_failwith("Cairo Context is not initialized");
    }

    cairo_rectangle(cairo_context, Double_val(x), Double_val(y), Double_val(w), Double_val(h));
    cairo_fill(cairo_context);

    return Val_unit;
}

CAMLprim value
console_draw_text(value x, value y, value size, value text)
{
    if (cairo_context == NULL) {
        caml_failwith("Cairo Context is not initialized");
    }

    // TODO(#28): font of the text is hardcoded
    cairo_select_font_face(
        cairo_context, "Sans",
        CAIRO_FONT_SLANT_NORMAL,
        CAIRO_FONT_WEIGHT_BOLD);
    cairo_set_font_size(cairo_context, Double_val(size));
    cairo_move_to(cairo_context, Double_val(x), Double_val(y));
    cairo_text_path(cairo_context, String_val(text));
    cairo_fill(cairo_context);

    return Val_unit;
}

CAMLprim value
console_clear(value r, value g, value b, value a)
{
    if (cairo_context == NULL) {
        caml_failwith("Cairo Context is not initialized");
    }

    cairo_set_source_rgba(cairo_context, Double_val(r), Double_val(g), Double_val(b), Double_val(a));
    cairo_paint(cairo_context);

    return Val_unit;
}

CAMLprim value
fill_chess_pattern(value unit)
{
    if (renderer == NULL) {
        caml_failwith("SDL Renderer is not initialized");
    }

    if (cairo_context == NULL) {
        caml_failwith("Cairo Context is not initialized");
    }

    SDL_Rect viewport;
    SDL_RenderGetViewport(renderer, &viewport);

    const int cell_size = 12;
    const int rows = (viewport.h + cell_size) / cell_size;
    const int columns = (viewport.w + cell_size) / cell_size;

    for (int y = 0; y < rows; ++y) {
        for (int x = 0; x < columns; ++x) {
            if ((x + y) % 2 == 0) {
                cairo_set_source_rgba(cairo_context, 0.25f, 0.25f, 0.25f, 1.0f);
            } else {
                cairo_set_source_rgba(cairo_context, 0.5f, 0.5f, 0.5f, 1.0f);
            }

            cairo_rectangle(
                cairo_context,
                (float) (x * cell_size), (float) (y * cell_size),
                (float) cell_size, (float) cell_size);
            cairo_fill(cairo_context);
        }
    }

    return Val_unit;
}

CAMLprim value
console_present(value unit)
{
    if (renderer == NULL) {
        caml_failwith("Renderer is not initialized");
    }

    if (cairo_context != NULL) {
        caml_failwith("Rendering inside of Cairo context");
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
console_fill_circle(value x, value y, value r)
{
    if (cairo_context == NULL) {
        caml_failwith("Cairo Context is not initialized");
    }

    cairo_arc(cairo_context,
              Double_val(x), Double_val(y), Double_val(r),
              0.0, 2 * M_PI);
    cairo_fill(cairo_context);

    return Val_unit;
}

CAMLprim value
start_cairo_render(value width, value height)
{
    if (cairo_surface != NULL) {
        fprintf(stderr, "[WARN] Cairo surface double initialization\n");
        return Val_unit;
    }

    cairo_surface = cairo_image_surface_create(
        CAIRO_FORMAT_ARGB32, Int_val(width), Int_val(height));
    cairo_context = cairo_create(cairo_surface);

    return Val_unit;
}

CAMLprim value
start_cairo_preview(value unit)
{
    if (texture == NULL) {
        caml_failwith("Texture is not initialized");
    }

    if (renderer == NULL) {
        caml_failwith("Renderer is not initialized");
    }

    if (cairo_surface != NULL) {
        fprintf(stderr, "[WARN] Cairo surface double initialization\n");
        return Val_unit;
    }

    SDL_Rect viewport;
    SDL_RenderGetViewport(renderer, &viewport);

    void *pixels;
    int pitch;

    SDL_LockTexture(texture, NULL, &pixels, &pitch);
    cairo_surface = cairo_image_surface_create_for_data(
        pixels,
        CAIRO_FORMAT_ARGB32,
        viewport.w, viewport.h, pitch);
    cairo_context = cairo_create(cairo_surface);

    return Val_unit;
}

CAMLprim value
stop_cairo_render(value filename)
{
    if (cairo_surface == NULL) {
        caml_failwith("Cairo Surface is not initialized");
    }

    cairo_status_t err = cairo_surface_write_to_png(cairo_surface, String_val(filename));
    if (err != 0) {
        caml_failwith(cairo_status_to_string(err));
    }

    cairo_destroy(cairo_context);
    cairo_context = NULL;

    cairo_surface_destroy(cairo_surface);
    cairo_surface = NULL;

    return Val_unit;
}

CAMLprim value
stop_cairo_preview(value unit)
{
    if (cairo_context != NULL) {
        cairo_destroy(cairo_context);
        cairo_context = NULL;
    }

    if (cairo_surface != NULL) {
        cairo_surface_destroy(cairo_surface);
        cairo_surface = NULL;
    }

    SDL_UnlockTexture(texture);

    return Val_unit;
}
