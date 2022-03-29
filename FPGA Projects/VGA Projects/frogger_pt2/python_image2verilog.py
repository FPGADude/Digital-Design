# *****************************************************************************
# Created by embeddedthoughts.com
# Edited by David J. Marion aka FPGA Dude
# Editor's notes:
#   - scipy misc.imread() is now a deprecated function
#   - scipy library is no longer needed in this program 
#       and is replaced with imageio library on line# 17
#   - line# 105 shows the replacement code using imageio.imread() 
#       for line# 103 with scipy.misc.imread()
# *****************************************************************************

# converts image to Verilog HDL that infers a ROM using Xilinx Block RAM
# note: 12-bit color map word is r3, r2, r1, r0, g3, g2, g1, g0, b3, b2, b1, b0

#from scipy import misc		# change1 from

import imageio			    # change1 to
import math

# returns string of 12-bit color at row x, column y of image
def get_color_bits(im, y, x):
    # convert color components to byte string and slice needed upper bits
    b  = format(im[y][x][0], 'b').zfill(8)
    rx = b[0:4]
    b  = format(im[y][x][1], 'b').zfill(8)
    gx = b[0:4]
    b  = format(im[y][x][2], 'b').zfill(8)
    bx = b[0:4]

    # return concatination of RGB bits
    return str(rx+gx+bx)

# write to file Verilog HDL
# takes name of file, image array,
# pixel coordinates of background color to mask as 0
def rom_12_bit(name, im, mask=False, rem_x=-1, rem_y=-1):

    # get colorbyte of background color
    # if coordinates left at default, map all data without masking
    if rem_x == -1 or rem_y == -1:
        a = "000000000000"
        
    # else set mask compare byte
    else:
        a = get_color_bits(im, rem_x, rem_y)

    # make output filename from input
    #file_name = name.split('.')[0] + "_12_bit_rom.v"	# changed from
    file_name = name.split('.')[0] + "_rom.v"		    # changed to(editor's preference)

    # open file
    f = open(file_name, 'w')

    # get image dimensions
    y_max, x_max, z = im.shape

    # get width of row and column case words
    row_width = math.ceil(math.log(y_max-1,2))
    col_width = math.ceil(math.log(x_max-1,2))

    # write beginning part of module up to case statements
    f.write("module " + name.split('.')[0] + "_rom\n\t(\n\t\t")
    f.write("input wire clk,\n\t\tinput wire [" + str(row_width-1) + ":0] row,\n\t\t")
    f.write("input wire [" + str(col_width-1) + ":0] col,\n\t\t")
    f.write("output reg [11:0] color_data\n\t);\n\n\t")
    f.write("(* rom_style = \"block\" *)\n\n\t//signal declaration\n\t")
    f.write("reg [" + str(row_width-1) + ":0] row_reg;\n\t")
    f.write("reg [" + str(col_width-1) + ":0] col_reg;\n\n\t")
    f.write("always @(posedge clk)\n\t\tbegin\n\t\trow_reg <= row;\n\t\tcol_reg <= col;\n\t\tend\n\n\t")
    f.write("always @*\n\tcase ({row_reg, col_reg})\n")
    

    # loops through y rows and x columns
    for y in range(y_max):
        for x in range(x_max):
            # write : color_data = 
            case = format(y, 'b').zfill(row_width) + format(x, 'b').zfill(col_width)
            f.write("\t\t" + str(row_width + col_width) + "'b" + case + ": color_data = " + str(12) + "'b")

            # if mask is set to false, just write color data
            if(mask == False):
                f.write(get_color_bits(im, y, x))
                f.write(";\n")

            elif(get_color_bits(im, y, x) != a):
                # write color bits to file
                f.write(get_color_bits(im, y, x))
                f.write(";\n")
                
            else:
                f.write("000000000000;\n")
                
        f.write("\n")
        
    # write end of module
    f.write("\t\tdefault: color_data = 12'b000000000000;\n\tendcase\nendmodule")

    # close file
    f.close()    

# driver function
def generate(name, rem_x=-1, rem_y=-1):
    #im = misc.imread(name, mode = 'RGB')	# change2 from    

    im = imageio.imread(name)			    # change2 to     
    print("width: " + str(im.shape[1]) + ", height: " + str(im.shape[0]))
    rom_12_bit(name, im)

# generate rom from full bitmap image
#generate("yoshi.bmp")      # original file in example on embeddedthoughts.com

generate("frog_up.bmp")     # <-- change your .bmp file name here