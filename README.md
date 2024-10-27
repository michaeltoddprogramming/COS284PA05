# COS284PA05 - PPM Image Processing

## Team Members
- **Michael Todd** (U23540223)
- **Corne de Lange** (U23788862)
- **Cobus Botha** (U23556502)

## Project Overview
This project involves processing PPM (Portable Pixmap) images using assembly language. The tasks include reading a PPM file, computing CDF (Cumulative Distribution Function) values, applying histogram equalization, and writing the processed image back to a PPM file.

## File Descriptions

### [task1_read_ppm_file.asm](task1_read_ppm_file.asm)
This file contains the code to read a binary P6 format PPM file and create a linked pixel structure. Each pixel connects to adjacent pixels (above, below, left, right).

Key functions:
- `readPPM`: Reads the PPM file and initializes the pixel structure.
- `skipComments`: Skips comment lines in the PPM file.

### [task2_compute_cdf_values.asm](task2_compute_cdf_values.asm)
This file contains the code to compute the CDF values from the pixel data.

Key functions:
- `computeCDFValues`: Computes the histogram and CDF values for the image.

### [task3_histogram_equalisation.asm](task3_histogram_equalisation.asm)
This file contains the code to apply histogram equalization to the image using the computed CDF values.

Key functions:
- `applyHistogramEqualization`: Applies histogram equalization to the pixel data.

### [task4_write_ppm.asm](task4_write_ppm.asm)
This file contains the code to write the processed image data back to a PPM file.

Key functions:
- `writePPM`: Writes the PPM header and pixel data to the output file.
