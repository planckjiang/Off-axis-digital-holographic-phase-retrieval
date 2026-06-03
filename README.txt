# Metasurface Angular Alignment Phase Extraction

This repository contains a MATLAB-based image processing pipeline designed for precise **spatial and angular alignment** verification in micro-nano optical systems (e.g., metasurfaces, lithography alignment subsystems). 

The algorithm extracts relative phase distributions from experimental interference/fringe patterns using localized Fourier-domain filtering and implements a phase-safe spatial interpolation technique.

## Key Features
* **Automated Data Sorting**: Automatically parses and orders experimental `.tif` image sequences based on numerical patterns (e.g., rotation angles) within filenames.
* **Fourier-Domain Filtering**: Constructs a customized elliptical Gaussian-tail passband filter around specific carrier frequency peaks to isolate target diffracted orders.
* **Phase-Safe Resampling**: Performs spatial interpolation in the complex domain (`exp(1i * phi)`) rather than direct phase values to effectively avoid $2\pi$ phase wrapping artifacts.
* **Dual ROI Profiling**: Simultaneously extracts and resamples phase distributions from multiple micro-structures or metasurface regions (e.g., RCP/LCP channels).

## Pipeline Workflow

1. **Image Preprocessing**: Loads raw experimental frames and an alignment reference image.
2. **FFT Filtering**: Transforms images to the frequency domain, applies the custom localized filter, and transforms back to the spatial domain.
3. **Phase Demodulation**: Computes the complex ratio between the filtered experimental frame and the reference frame to extract the relative phase wrapped within $[-\pi, \pi]$.
4. **ROI Resampling**: Crops user-defined regions of interest corresponding to specific metasurface marks and upsamples them to target matrices using bicubic interpolation.

## Prerequisites
* **MATLAB** (R2021a or later recommended)
* **Image Processing Toolbox**

## Usage
1. Clone this repository to your local machine:
   ```bash
   git clone [https://github.com/yourusername/Metasurface-Angular-Alignment.git](https://github.com/yourusername/Metasurface-Angular-Alignment.git)