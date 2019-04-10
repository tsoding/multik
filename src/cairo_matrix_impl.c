#include <caml/mlvalues.h>
#include <caml/fail.h>
#include <caml/alloc.h>
#include <caml/custom.h>
#include <caml/memory.h>

#include <cairo.h>

void mat_ocaml_to_cairo(value input, cairo_matrix_t *output)
{
    output->xx = Double_val(Field(input, 0));
    output->xy = Double_val(Field(input, 1));
    output->x0 = Double_val(Field(input, 2));
    output->yx = Double_val(Field(input, 3));
    output->yy = Double_val(Field(input, 4));
    output->y0 = Double_val(Field(input, 5));
}

static void mat_cairo_to_ocaml(cairo_matrix_t *input, value output)
{
    Store_field(output, 0, caml_copy_double(input->xx));
    Store_field(output, 1, caml_copy_double(input->xy));
    Store_field(output, 2, caml_copy_double(input->x0));
    Store_field(output, 3, caml_copy_double(input->yx));
    Store_field(output, 4, caml_copy_double(input->yy));
    Store_field(output, 5, caml_copy_double(input->y0));
}

CAMLprim value
multik_cairo_matrix_product(value m1, value m2)
{
    CAMLparam2(m1, m2);
    value result = caml_alloc(9, 0);

    cairo_matrix_t a, b, c;
    mat_ocaml_to_cairo(m1, &a);
    mat_ocaml_to_cairo(m2, &b);
    cairo_matrix_multiply(&c, &a, &b);

    mat_cairo_to_ocaml(&c, result);

    CAMLreturn(result);
}

CAMLprim value
multik_cairo_matrix_id(value unit)
{
    CAMLparam1(unit);
    value result = caml_alloc(9, 0);

    cairo_matrix_t a;
    cairo_matrix_init_identity(&a);
    mat_cairo_to_ocaml(&a, result);

    CAMLreturn(result);
}

CAMLprim value
multik_cairo_matrix_translate(value vec)
{
    CAMLparam1(vec);
    value result = caml_alloc(9, 0);

    cairo_matrix_t a;
    cairo_matrix_init_translate(
        &a, Double_val(Field(vec, 0)),
        Double_val(Field(vec, 1)));
    mat_cairo_to_ocaml(&a, result);

    CAMLreturn(result);
}

CAMLprim value
multik_cairo_matrix_scale(value vec)
{
    CAMLparam1(vec);
    value result = caml_alloc(9, 0);

    cairo_matrix_t a;
    cairo_matrix_init_scale(
        &a, Double_val(Field(vec, 0)),
        Double_val(Field(vec, 1)));
    mat_cairo_to_ocaml(&a, result);

    CAMLreturn(result);
}

CAMLprim value
multik_cairo_matrix_rotate(value angle)
{
    CAMLparam1(angle);
    value result = caml_alloc(9, 0);

    cairo_matrix_t a;
    cairo_matrix_init_rotate(&a, Double_val(angle));
    mat_cairo_to_ocaml(&a, result);

    CAMLreturn(result);
}

CAMLprim value
multik_cairo_matrix_invert(value m)
{
    CAMLparam1(m);
    value result = caml_alloc(9, 0);

    cairo_matrix_t a;
    mat_ocaml_to_cairo(m, &a);
    cairo_status_t res = cairo_matrix_invert(&a);
    if (res != CAIRO_STATUS_SUCCESS) {
        caml_failwith(cairo_status_to_string(res));
    }
    mat_cairo_to_ocaml(&a, result);

    CAMLreturn(result);
}
