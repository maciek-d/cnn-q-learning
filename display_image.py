import matplotlib.pyplot as plot
import math
# def  __init__(self, dpi=80.0, x_pixels=780, y_pixels=780):
class Render:
    def __init__(self, dpi=80.0, x_pixels=780, y_pixels=780):
        self.dpi = dpi
        self.x_pixels, self.y_pixels = x_pixels, y_pixels

    def draw(self, image):
        plot.gray()
        x = image.shape[0]
        y = image.shape[1]

        fig = plot.figure(figsize=(y / self.dpi, x / self.dpi), dpi=self.dpi)
        fig.figimage(image)
        plot.show()

    def __call__(self, image, *args, **kwargs):
        plot.gray()
        if len(args) == 2:
            self.x_pixels = args[0]
            self.y_pixels = args[1]
        fig = plot.figure(figsize=(self.y_pixels / self.dpi, self.x_pixels / self.dpi), dpi=self.dpi)
        image_height = 100
        image_width = 75
        n_images = 7
        for offset in range(int(math.ceil(image.shape[0]/(n_images*image_height)))):
            if (offset+1)*image_height*n_images < image.shape[0]*image.shape[1]:
                fig.figimage(image[offset*image_height*n_images:(offset+1)*image_height*n_images], offset*image_width, 30)
            else:
                fig.figimage(image[offset * image_height * n_images:], offset * image_width, 30)
        plot.show()

