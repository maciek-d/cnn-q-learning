import os
import time
import numpy as np
from PIL import ImageGrab


class Graphics:
    def __init__(self, frames_per_choice=5):
        self.frames_per_choice = frames_per_choice
        self.image_number = 0
        self.screenshot_indicator = "screenshot_.dat"


    def __call__(self, training):
        if not training:
            self.frames_per_choice = 1  # make screenshot every choice if not training
        for i in range(self.frames_per_choice):
            indicator = self.screenshot_indicator.replace('_', str(self.image_number + 1))
            while not os.path.exists(indicator):
                time.sleep(.01)
            self.image_number += 1
            image = self.screenshot(self.image_number)
        self.frames_per_choice = 5  # return to making screenshot every 5th frame
        return image

    def get_initial_screen(self):
        indicator = self.screenshot_indicator.replace('_', str(0))
        while not os.path.exists(indicator):
            time.sleep(.01)
        return self.screenshot(self.image_number)

    @staticmethod
    def remove(file_name):
        remove_loop = True
        while remove_loop:
            try:
                os.remove(file_name)
                remove_loop = False
            except Exception:
                # print('cannot remove ', file_name)
                time.sleep(.01)

    def screenshot(self, file_name, dir='./snaps/', box=(1, 51, 257, 291)):
        path = dir + str(file_name) + '.png'
        screen = ImageGrab.grab(bbox=box)
        screen.save(path, "PNG")
        indicator = self.screenshot_indicator.replace('_', str(file_name))
        if os.path.exists(indicator):
            self.remove(indicator)
        else:
            print("Something went wrong file did not exist")
        return np.asarray(screen, dtype="int32")
