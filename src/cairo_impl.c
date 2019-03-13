#include <stdio.h>
#include <math.h>

#include <caml/mlvalues.h>
#include <caml/fail.h>
#include <caml/alloc.h>
#include <caml/custom.h>
#include <caml/memory.h>
#include <cairo.h>

struct Context
{
    cairo_surface_t *surface;
    cairo_t *context;
};

CAMLprim value
multik_cairo_make(value width, value height)
{
    printf("Creating context %d by %d\n", Int_val(width), Int_val(height));

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
multik_cairo_make_from_texture(value texture)
{
    // TODO: multik_cairo_make_from_texture is not implemented
    return (value) NULL;
}

CAMLprim value
multik_cairo_free(value context_value)
{
    struct Context *context = (struct Context *) context_value;

    if (context == NULL) {
        caml_failwith("Context is NULL");
    }

    printf("Destroy context %d by %d\n",
           cairo_image_surface_get_width(context->surface),
           cairo_image_surface_get_height(context->surface));

    if (context->context) {
        cairo_destroy(context->context);
    }

    if (context->surface) {
        cairo_surface_destroy(context->surface);
    }

    free(context);

    return Val_unit;
}

CAMLprim value
multik_cairo_set_fill_color(value context_value, value r, value g, value b, value a)
{
    struct Context *context = (struct Context *) context_value;

    if (context == NULL) {
        caml_failwith("Context is NULL");
    }

    cairo_set_source_rgba(context->context,
                          Double_val(r), Double_val(g), Double_val(b),
                          Double_val(a));

    return Val_unit;
}

CAMLprim value
multik_cairo_fill_rect(value context_value, value x, value y, value w, value h)
{
    struct Context *context = (struct Context *) context_value;

    if (context == NULL) {
        caml_failwith("Context is NULL");
    }

    cairo_rectangle(context->context, Double_val(x), Double_val(y), Double_val(w), Double_val(h));
    cairo_fill(context->context);

    return Val_unit;
}

CAMLprim value
multik_cairo_fill_circle(value context_value, value x, value y, value r)
{
    struct Context *context = (struct Context *) context_value;

    if (context == NULL) {
        caml_failwith("Context is NULL");
    }

    cairo_arc(context->context,
              Double_val(x), Double_val(y), Double_val(r),
              0.0, 2 * M_PI);
    cairo_fill(context->context);

    return Val_unit;
}

CAMLprim value
multik_cairo_draw_text(value *argv, value argn)
{
    const struct Context *context = (struct Context *) argv[0];
    const float x = Double_val(argv[1]);
    const float y = Double_val(argv[2]);
    const char *font_name = String_val(argv[3]);
    const double font_size = Double_val(argv[4]);
    const char *text = String_val(argv[5]);

    cairo_select_font_face(
        context->context, String_val(font_name),
        CAIRO_FONT_SLANT_NORMAL,
        CAIRO_FONT_WEIGHT_BOLD);
    cairo_set_font_size(context->context, font_size);
    cairo_move_to(context->context, x, y);
    cairo_text_path(context->context, text);
    cairo_fill(context->context);

    return Val_unit;
}

CAMLprim value
multik_cairo_boundary_text(value *argv, value argn)
{
    CAMLparamN(argv, argn);
    CAMLlocal1(ab);

    ab = caml_alloc(2, 0);

    const struct Context *context = (struct Context *) argv[0];
    const float x = Double_val(argv[1]);
    const float y = Double_val(argv[2]);
    const char *font_name = String_val(argv[3]);
    const float font_size = Double_val(argv[4]);
    const char *text = String_val(argv[5]);

    cairo_select_font_face(
        context->context, String_val(font_name),
        CAIRO_FONT_SLANT_NORMAL,
        CAIRO_FONT_WEIGHT_BOLD);
    cairo_set_font_size(context->context, font_size);
    cairo_move_to(context->context, x, y);

    cairo_text_extents_t extents;
    cairo_text_extents(context->context, text, &extents);

    Store_field(ab, 0, caml_copy_double(extents.width));
    Store_field(ab, 1, caml_copy_double(extents.height));

    CAMLreturn(ab);
}

CAMLprim value
multik_cairo_save_to_png(value context_value, value filename)
{
    const struct Context *context = (struct Context *)context_value;

    if (!context) {
        return Val_unit;
    }

    cairo_status_t res = cairo_surface_write_to_png(context->surface, String_val(filename));
    if (res != CAIRO_STATUS_SUCCESS) {
        caml_failwith(cairo_status_to_string(res));
    }

    return Val_unit;
}
