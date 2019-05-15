#include <stdio.h>
#include <math.h>
#include <assert.h>

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

/* TODO(#114): Image cache is linear */
#define CACHE_CAPACITY 1024
cairo_surface_t *cache_surface[CACHE_CAPACITY];
const char *cache_filename[CACHE_CAPACITY];
size_t cache_count = 0;

static cairo_surface_t *multik_image_cache_get(const char *filename)
{
    int index = -1;
    for (size_t i = 0; i < cache_count; ++i) {
        if (strcmp(filename, cache_filename[i]) == 0) {
            index = i;
            break;
        }
    }

    if (index < 0) {
        assert(cache_count < CACHE_CAPACITY);
        cache_filename[cache_count] = strdup(filename);
        cache_surface[cache_count] = cairo_image_surface_create_from_png(filename);
        return cache_surface[cache_count++];
    }

    return cache_surface[index];
}

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
multik_cairo_draw_image(value context_value,
                        value filepath)
{
    CAMLparam2(context_value, filepath);
    struct Context *context = (struct Context *) context_value;

    if (context == NULL) {
        caml_failwith("Context is NULL");
    }

    cairo_surface_t *image =
        multik_image_cache_get(String_val(filepath));
    assert(image);
    const int width = cairo_image_surface_get_width(image);
    const int height = cairo_image_surface_get_height(image);

    cairo_set_source_surface(
        context->context,
        image,
        0.0, 0.0);
    cairo_rectangle(context->context, 0.0, 0.0,
                    width, height);
    cairo_fill(context->context);

    CAMLreturn(Val_unit);
}

CAMLprim value
multik_cairo_boundary_image(value filepath)
{
    CAMLparam1(filepath);
    CAMLlocal1(boundary);
    /* TODO(#115): multik_cairo_boundary_image is not implement */
    Store_field(boundary, 0, caml_copy_double(0.0));
    Store_field(boundary, 1, caml_copy_double(0.0));
    CAMLreturn(boundary);
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

void mat_ocaml_to_cairo(value input, cairo_matrix_t *output);

CAMLprim value
multik_cairo_transform(value context_value, value matrix_tuple)
{
    CAMLparam2(context_value, matrix_tuple);
    const struct Context *context = (struct Context *)context_value;

    if (context == NULL) {
        caml_failwith("Context is NULL!");
    }

    cairo_matrix_t matrix;
    mat_ocaml_to_cairo(matrix_tuple, &matrix);
    cairo_transform(context->context, &matrix);

    CAMLreturn(Val_unit);
}
