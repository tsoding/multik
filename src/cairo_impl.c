#include <stdio.h>
#include <math.h>

#include <caml/mlvalues.h>
#include <caml/fail.h>
#include <caml/alloc.h>
#include <caml/custom.h>
#include <caml/memory.h>

#include <SDL2/SDL.h>

#include <cairo.h>

struct Context
{
    cairo_surface_t *surface;
    cairo_t *context;
    SDL_Texture *texture;
};

CAMLprim value
multik_cairo_make(value width, value height)
{
    const char *error_message = "";

    struct Context *context = malloc(sizeof(struct Context));
    if (context == NULL) {
        error_message = "Could not allocate memory. Download more RAM.";
        goto fail;
    }

    context->surface = cairo_image_surface_create(
        CAIRO_FORMAT_ARGB32,
        Int_val(width), Int_val(height));
    if (context->surface == NULL) {
        error_message = "Could not allocate Cairo surface";
        goto fail;
    }

    context->context = cairo_create(context->surface);
    if (context->context == NULL) {
        error_message = "Could not allocate Cairo context";
        goto fail;
    }

    context->texture = NULL;

    return (value) context;

fail:
    if (context != NULL) {
        if (context->context) {
            cairo_destroy(context->context);
        }

        if (context->surface) {
            cairo_surface_destroy(context->surface);
        }

        free(context);
    }

    caml_failwith(error_message);

    return (value) NULL;
}

CAMLprim value
multik_cairo_make_from_texture(value texture_value)
{
    const char *error_message = NULL;

    struct Context *context = malloc(sizeof(struct Context));
    if (context == NULL) {
        error_message = "Could not allocate memory. Download more RAM.";
        goto fail;
    }

    SDL_Texture *texture = (SDL_Texture*) texture_value;

    if (texture == NULL) {
        error_message = "Texture is NULL!";
        goto fail;
    }

    int w, h;

    if (SDL_QueryTexture(texture, NULL, NULL, &w, &h) < 0) {
        error_message = SDL_GetError();
        goto fail;
    }

    void *pixels;
    int pitch;

    if (SDL_LockTexture(texture, NULL, &pixels, &pitch) < 0) {
        error_message = SDL_GetError();
        goto fail;
    }

    context->surface = cairo_image_surface_create_for_data(
        pixels,
        CAIRO_FORMAT_ARGB32,
        w, h, pitch);
    if (context->surface == NULL) {
        error_message = "Could not allocate Cairo surface";
        goto fail;
    }

    context->context = cairo_create(context->surface);
    if (context->context == NULL) {
        error_message = "Could not allocate Cairo context";
        goto fail;
    }

    context->texture = texture;

    return (value) context;

fail:

    if (context != NULL) {
        if (context->context) {
            cairo_destroy(context->context);
        }

        if (context->surface) {
            cairo_surface_destroy(context->surface);

            if (texture) {
                SDL_UnlockTexture(texture);
            }
        }

        free(context);
    }

    caml_failwith(error_message);

    return (value) NULL;
}

CAMLprim value
multik_cairo_free(value context_value)
{
    struct Context *context = (struct Context *) context_value;

    if (context == NULL) {
        caml_failwith("Context is NULL");
    }

    if (context->context) {
        cairo_destroy(context->context);
    }

    if (context->surface) {
        cairo_surface_destroy(context->surface);
    }

    if (context->texture) {
        SDL_UnlockTexture(context->texture);
    }

    free(context);

    return Val_unit;
}

CAMLprim value
multik_fill_chess_pattern(value context_value)
{
    struct Context *context = (struct Context *) context_value;

    if (context == NULL) {
        caml_failwith("Context is NULL");
    }

    double x1, y1, x2, y2;
    cairo_clip_extents(context->context, &x1, &y1, &x2, &y2);
    const int w = x2 - x1;
    const int h = y2 - y1;

    const int cell_size = 12;
    const int rows = (h + cell_size) / cell_size;
    const int columns = (w + cell_size) / cell_size;


    for (int y = 0; y < rows; ++y) {
        for (int x = 0; x < columns; ++x) {
            if ((x + y) % 2 == 0) {
                cairo_set_source_rgba(context->context, 0.25f, 0.25f, 0.25f, 1.0f);
            } else {
                cairo_set_source_rgba(context->context, 0.5f, 0.5f, 0.5f, 1.0f);
            }

            cairo_rectangle(
                context->context,
                (float) (x * cell_size), (float) (y * cell_size),
                (float) cell_size, (float) cell_size);
            cairo_fill(context->context);
        }
    }

    return Val_unit;
}

CAMLprim value
multik_cairo_set_fill_color(value context_value, value color)
{
    CAMLparam2(context_value, color);
    CAMLlocal4(r, g, b, a);

    r = Field(color, 0);
    g = Field(color, 1);
    b = Field(color, 2);
    a = Field(color, 3);

    struct Context *context = (struct Context *) context_value;

    if (context == NULL) {
        caml_failwith("Context is NULL");
    }

    cairo_set_source_rgba(context->context,
                          Double_val(r), Double_val(g), Double_val(b),
                          Double_val(a));

    CAMLreturn(Val_unit);
}

CAMLprim value
multik_cairo_fill_rect(value context_value, value rect)
{
    CAMLparam2(context_value, rect);
    CAMLlocal4(x, y, w, h);

    x = Field(rect, 0);
    y = Field(rect, 1);
    w = Field(rect, 2);
    h = Field(rect, 3);

    struct Context *context = (struct Context *) context_value;

    if (context == NULL) {
        caml_failwith("Context is NULL");
    }

    cairo_rectangle(context->context, Double_val(x), Double_val(y), Double_val(w), Double_val(h));
    cairo_fill(context->context);

    CAMLreturn(Val_unit);
}

CAMLprim value
multik_cairo_fill_circle(value context_value, value center, value r)
{
    CAMLparam3(context_value, center, r);
    CAMLlocal2(x, y);

    x = Field(center, 0);
    y = Field(center, 1);

    struct Context *context = (struct Context *) context_value;

    if (context == NULL) {
        caml_failwith("Context is NULL");
    }

    cairo_arc(context->context,
              Double_val(x), Double_val(y), Double_val(r),
              0.0, 2 * M_PI);
    cairo_fill(context->context);

    CAMLreturn(Val_unit);
}

CAMLprim value
multik_cairo_draw_text(value context_value,
                       value position,
                       value font,
                       value text)
{
    CAMLparam4(context_value, position, font, text);
    CAMLlocal4(x, y, font_name, font_size);

    x = Field(position, 0);
    y = Field(position, 1);
    font_name = Field(font, 0);
    font_size = Field(font, 1);

    const struct Context *context = (struct Context *) context_value;

    cairo_select_font_face(
        context->context, String_val(font_name),
        CAIRO_FONT_SLANT_NORMAL,
        CAIRO_FONT_WEIGHT_BOLD);
    cairo_set_font_size(context->context, Double_val(font_size));
    cairo_move_to(context->context, Double_val(x), Double_val(y));
    cairo_text_path(context->context, String_val(text));
    cairo_fill(context->context);

    CAMLreturn(Val_unit);
}

CAMLprim value
multik_cairo_boundary_text(value context_value,
                           value position,
                           value font,
                           value text)
{
    CAMLparam4(context_value, position, font, text);
    CAMLlocal5(x, y, font_name, font_size, boundary);

    x = Field(position, 0);
    y = Field(position, 1);
    font_name = Field(font, 0);
    font_size = Field(font, 1);
    boundary = caml_alloc(2, 0);

    const struct Context *context = (struct Context *) context_value;

    cairo_select_font_face(
        context->context, String_val(font_name),
        CAIRO_FONT_SLANT_NORMAL,
        CAIRO_FONT_WEIGHT_BOLD);
    cairo_set_font_size(context->context, Double_val(font_size));
    cairo_move_to(context->context, Double_val(x), Double_val(y));

    cairo_text_extents_t extents;
    cairo_text_extents(context->context, String_val(text), &extents);

    Store_field(boundary, 0, caml_copy_double(extents.width));
    Store_field(boundary, 1, caml_copy_double(extents.height));

    CAMLreturn(boundary);
}

CAMLprim value
multik_cairo_save_to_png(value context_value, value filename)
{
    const struct Context *context = (struct Context *)context_value;

    if (context == NULL) {
        caml_failwith("Context is NULL!");
    }

    cairo_status_t res = cairo_surface_write_to_png(context->surface, String_val(filename));
    if (res != CAIRO_STATUS_SUCCESS) {
        caml_failwith(cairo_status_to_string(res));
    }

    return Val_unit;
}
