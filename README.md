# InterpolationFilters

InterpolationFilters is a university project developed by Andrea Giannini at Politecnico di Torino. It is composed of 4 hardware architectures:

- [Luma legacy]
- [Luma approximate]
- [Chroma legacy]
- [Chroma approximate]

The legacy architectures are fully standard compliant with the HEVC interpolation process, implementing an optimized multiplier-less two-dimensional filter architectures. Hardware reconfiguration, throughput adaption, on-chip storage have been exploited in order to reduce both the power and the energy consumption.

The approximate architectures implement a certain number of filters in parallel to the legacy one, with lower number of taps in order to reduce the power/energy consumption for acceptable lowering in the output video quality:
1. Luma approximate:
	- Legacy reconfigurable filter (8/7 taps)
	- 3-tap reconfigurable filter
	- 5-tap reconfigurable filter
2. Chroma approximate:
	- Legacy reconfigurable filter (4 taps)
	- 2-tap filter

Spreadsheets containing the results obtained with the [umc 65 nm] technology have been reported [here].

## Documentation
A brief animation of the two-dimensional [filtering approach] implemented by all the architectures proposed has been reproduced.
In [InterpolationFilters.pdf] an overview of the architectures implemented has been reported, with figures showing the main blocks of the luma legacy and approximate designs.


[Luma legacy]: <https://github.com/Jak94/InterpolationFilters/blob/master/RTL/Legacy/Luma/ProcessingElement.vhd>
[Luma approximate]: <https://github.com/Jak94/InterpolationFilters/blob/master/RTL/Approximate/Luma/ProcessingElement_approximate.vhd>
[Chroma legacy]: <https://github.com/Jak94/InterpolationFilters/blob/master/RTL/Legacy/Chroma/ProcessingElement_chroma.vhd>
[Chroma approximate]: <https://github.com/Jak94/InterpolationFilters/blob/master/RTL/Approximate/Chroma/ProcessingElement_chroma_approximate.vhd>
[umc 65 nm]: <http://www.umc.com/english/pdf/UMC%2065nm.pdf>
[here]: <https://github.com/Jak94/InterpolationFilters/blob/master/umc65_results.xlsx>
[filtering approach]: <https://github.com/Jak94/InterpolationFilters/blob/master/filtering_example.pptx>
[InterpolationFilters.pdf]: <https://github.com/Jak94/InterpolationFilters/blob/master/InterpolationFilters.pdf>
