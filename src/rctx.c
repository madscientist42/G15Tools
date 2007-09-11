/*
    This file is part of g15tools.

    g15tools is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    g15tools is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with g15lcd; if not, write to the Free Software
    Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA

    $Id$
*/

#include <stdlib.h>
#include <string.h>
#include "libg15render.h"

// Magic indentifier for the render context structure.
#define G15R_RCTX_MAGIC 0xa358

struct render_context_s {
    unsigned short int magic;
    g15canvas *canvas;
    char *name;
    struct render_context_s *next;
};

typedef struct render_context_s render_context_t;

// Linked list of allocated render contexts.
static render_context_t *rctxlist = NULL;

// Currently active render context;
static render_context_t *c_rctx = NULL;

int
g15r_rctx_get_context_from_name (render_context_t *rctx, const char *name)
{
    render_context_t *search;

    if(name == NULL) return G15R_ERROR_RCTX_NOT_FOUND;

    search = rctxlist;
    while (search != NULL) {
        if(strlen (search->name) == strlen(name)) {
            if(strcmp (search->name, name) == 0) {
                rctx = search;
                return G15R_ERROR_NONE;
            }
        }
        search = search->next;
    }
    return G15R_ERROR_RCTX_NOT_FOUND;
}

int
g15r_rctx_set_active_context (render_context_t *rctx)
{
    if(rctx == NULL || rctx->magic != G15R_RCTX_MAGIC) return G15R_ERROR_INVALID_RCTX;
    c_rctx = rctx;
    return G15R_ERROR_NONE;
}

int
g15r_rctx_set_active_context_with_name (const char *name)
{
    render_context_t *search = NULL;

    if(name == NULL || name == "") return G15R_ERROR_PARAMETER;

    if(g15r_rctx_get_context_from_name (search, name) == G15R_ERROR_NONE) {
        return g15r_rctx_set_active_context (search);
    }
    return G15R_ERROR_RCTX_NOT_FOUND;
}

int
g15r_rctx_new (render_context_t *rctx, const char *name, g15r_bool_t activate)
{
    render_context_t *search = NULL;
    g15canvas *canvas_new;

    if(rctx == NULL)
        return G15R_ERROR_PARAMETER;

    if(g15r_rctx_get_context_from_name (search, name) == G15R_ERROR_NONE) {
        rctx = search;
    } else {
        if((canvas_new = calloc (1, sizeof (g15canvas))) == NULL)
            return G15R_ERROR_OUT_OF_MEMORY;

        if((rctx = calloc (1, sizeof (render_context_t))) == NULL) {
            free (canvas_new);
            return G15R_ERROR_OUT_OF_MEMORY;
        }

        if((rctx->name = malloc (strlen (name) + 1)) == NULL) {
            free (rctx); rctx = NULL;
            free (canvas_new);
            return G15R_ERROR_OUT_OF_MEMORY;
        }

        rctx->magic = G15R_RCTX_MAGIC;
        rctx->canvas = canvas_new;
        memcpy (rctx->name, name, strlen (name));
        rctx->next = rctxlist;
        rctxlist = rctx;
    }
    if(activate) g15r_rctx_set_active_context (rctx);
    return G15R_ERROR_NONE;
}

int
g15r_rctx_release_context(render_context_t *rctx)
{
	if(rctx == NULL)
		return G15R_ERROR_PARAMETER;

	render_context_t *prev = NULL;
	render_context_t *cur = rctxlist;

	while(cur != NULL)
	{
		if(rctx == cur)
		{
			if(prev != NULL)
				prev->next = cur->next;

			if(c_rctx == rctx)
				c_rctx = cur->next;

			free(rctx->canvas);
			free(rctx->name);
			free(rctx);
			return G15R_ERROR_NONE;
		} else {
			prev = cur;
			cur = cur->next;
		}
	}
	return G15R_ERROR_RCTX_NOT_FOUND;
}

int
g15r_rctx_release_context_with_name (const char *name)
{
	render_context_t *search = NULL;

	if(name == NULL || name == "") return G15R_ERROR_PARAMETER;

	if(g15r_rctx_get_context_from_name (search, name) == G15R_ERROR_NONE) {
		return g15r_rctx_release_context (search);
	}
	return G15R_ERROR_RCTX_NOT_FOUND;
}

void
g15r_rctx_release_all_contexts (void)
{
    render_context_t *tmp;

    while (rctxlist) {
        free (rctxlist->canvas);
        free (rctxlist->name);
        tmp = rctxlist->next;
        free (rctxlist);
        rctxlist = tmp;
    }

    c_rctx = NULL;
    rctxlist = NULL;
}
