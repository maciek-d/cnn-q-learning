from skimage import io
import time
import os
import display_image as display
class GameDisplay:

    def __init__(self):
        self.emulator_crashed = False
        self.file_path = './snaps/Super Mario Bros (E)-_.PNG'
        self.choice_path = 'lua_data.dat'
        self.remove = False
        self.fetch_image_attempt = 0
        self.choice_file_attempts = 0
        self.offset = 0
        return

    def recover_from_crash(self, image_number):
        print("Recovered from crash")
        time.sleep(1)
        # my_file_path = self.file_path.replace('_', str(image_number-self.offset))
        # while not os.path.exists(my_file_path):
        #     self.offset += 1
        #     my_file_path = self.file_path.replace('_', str(image_number - self.offset))

        return

    def get_image(self, image_number):
        my_file_path = self.file_path.replace('_', str(image_number))
        while os.path.exists(self.choice_path):
            self.choice_file_attempts += 1
            if self.choice_file_attempts > 40 and image_number > 0:
                self.emulator_crashed = True
            time.sleep(.1)

        self.choice_file_attempts = 0
        if self.emulator_crashed:
            self.recover_from_crash(image_number)
            self.emulator_crashed = False

        while not os.path.exists(my_file_path):
            time.sleep(.1)
        try:
            image = io.imread(my_file_path)
        except Exception as inst:
            # print('couldnt read: ', my_file_path)
            time.sleep(.1)
            self.fetch_image_attempt += 1
            if self.fetch_image_attempt > 2:
                time.sleep(.25)

            return self.get_image(image_number)
        self.fetch_image_attempt = 0
        return image

    # def get_image(self):
    #     my_file_path = self.file_path.replace('_', str(0))
    #     while not os.path.exists(my_file_path):
    #         time.sleep(.1)
    #     image = io.imread(my_file_path)
    #     if self.remove:
    #         os.remove(my_file_path)
    #     else:
    #         self.remove = True
    #     return image



