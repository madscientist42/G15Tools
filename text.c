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
*/

#include "libg15render.h"

void g15r_renderCharacterLarge(g15canvas *canvas, int col, int row, unsigned char character, unsigned int sx, unsigned int sy)
{
   int helper = character * 8; // for our font which is 8x8
   
   int top_left_pixel_x = sx+col*(8); // 1 pixel spacing
   int top_left_pixel_y = sy+row*(8); // once again 1 pixel spacing
   
   int x, y;
   for (y=0;y<8;++y)
   {
      for (x=0;x<8;++x)
      {
         char font_entry = fontdata_8x8[helper + y];
        
         if (font_entry & 1<<(7-x))       
            g15r_setPixel(canvas, top_left_pixel_x + x, top_left_pixel_y + y, G15_COLOR_BLACK);
         else
            g15r_setPixel(canvas, top_left_pixel_x + x, top_left_pixel_y + y, G15_COLOR_WHITE);
         
      }
   }
}

void g15r_renderCharacterMedium(g15canvas *canvas, int col, int row, unsigned char character, unsigned int sx, unsigned int sy)
{
   int helper = character * 7 * 5; // for our font which is 6x4
   
   int top_left_pixel_x = sx+col*(5); // 1 pixel spacing
   int top_left_pixel_y = sy+row*(7); // once again 1 pixel spacing
   
   int x, y;
   for (y=0;y<7;++y)
   {
      for (x=0;x<5;++x)
      {
         char font_entry = fontdata_7x5[helper + y * 5 + x];
         if (font_entry)       
            g15r_setPixel(canvas, top_left_pixel_x + x, top_left_pixel_y + y, G15_COLOR_BLACK);
         else
            g15r_setPixel(canvas, top_left_pixel_x + x, top_left_pixel_y + y, G15_COLOR_WHITE);
         
      }
   }
}

void g15r_renderCharacterSmall(g15canvas *canvas, int col, int row, unsigned char character, unsigned int sx, unsigned int sy)
{
   int helper = character * 6 * 4; // for our font which is 6x4
   
   int top_left_pixel_x = sx+col*(4); // 1 pixel spacing
   int top_left_pixel_y = sy+row*(6); // once again 1 pixel spacing
   
   int x, y;
   for (y=0;y<6;++y)
   {
      for (x=0;x<4;++x)
      {
         char font_entry = fontdata_6x4[helper + y * 4 + x];
         if (font_entry)       
            g15r_setPixel(canvas, top_left_pixel_x + x, top_left_pixel_y + y, G15_COLOR_BLACK);
         else
            g15r_setPixel(canvas, top_left_pixel_x + x, top_left_pixel_y + y, G15_COLOR_WHITE);
         
      }
   }
}

void g15r_renderString(g15canvas *canvas, unsigned char stringOut[], int row, int size, unsigned int sx, unsigned int sy)
{

   int i=0;
   for (i; stringOut[i] != NULL; ++i)
   {
   	   switch (size) {
   	   		case G15_TEXT_SMALL:
   	   		{
	   	      g15r_renderCharacterSmall(canvas, i,row,stringOut[i],sx,sy);
	   	      break;
   	   		}
   	   		case G15_TEXT_MED:
   	   		{
	          g15r_renderCharacterMedium(canvas, i,row,stringOut[i],sx,sy);
	          break;
   	   		}
   	   		case G15_TEXT_LARGE:
   	   		{
	          g15r_renderCharacterLarge(canvas, i,row,stringOut[i],sx,sy);
	          break;
   	   		}
   	   		default:
   	   		  break;
   	   }
   }
   
}

void g15r_loadFont(g15canvas * canvas, char fontname[], int fontsize, int face_num)
{
	int errcode = 0;

    if(face_num<0) 
        face_num=0;
    if(face_num>MAX_FACE) 
        face_num=MAX_FACE; 

    if(canvas->ttf_fontsize[face_num])
        FT_Done_Face(canvas->face[face_num][0]); // destroy the last face

    if(!canvas->ttf_fontsize[face_num] && !fontsize) 
        canvas->ttf_fontsize[face_num] = 10;
    else
    	canvas->ttf_fontsize[face_num] = fontsize;

    errcode = FT_New_Face (canvas->ftLib,fontname,0,&face[face_num][0]);
    if(errcode) {
        canvas->ttf_fontsize[face_num]=0;
    }else{
        if(canvas->ttf_fontsize[face_num] && FT_IS_SCALABLE(canvas->face[face_num][0]))
            errcode = FT_Set_Char_Size(canvas->face[face_num][0],0,canvas->ttf_fontsize[face_num]*64,90,0);
        canvas->current_face = face_num;
    }
}
