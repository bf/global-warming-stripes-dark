import sys
import colorsys

if __name__ == "__main__":
    if len(sys.argv) != 4:
        print("Usage: python hls_to_rgb.py hue lightness saturation ")
        sys.exit(1)

    hue = float(sys.argv[1])
    lightness = float(sys.argv[2])
    saturation = float(sys.argv[3])

    r, g, b = colorsys.hls_to_rgb(hue / 360.0, lightness, saturation)
    print('#%02x%02x%02x'%(round(r*255),round(g*255),round(b*255)))

