import random
import numpy as np
import game_graphics as window
import agent_test
import time

import display_image as image_test
from skimage import transform
from skimage.color import rgb2gray

import os

q_learning_rate = .0001
gamma = .95
# living_penalty = -0.2 #-.05

n_choices = 3

TEMPERATURE = 12.0
# set the known q_values
REWARD_VALUE = 1.0
FORWARD_REWARD = 0.7
DEATH_PENALTY = -10.0
WRONG_DIR_PENALTY = -0.5
STANDING_PENALTY = -0.25

DEATH_SCORE = -1

STATE_X = 160
STATE_Y = 160

graphics = window.Graphics()
render_img = image_test.Render()
cutscene_indicator = "loop_screenshot.dat"
steps_no_improvement = 0

def delete_previous_data():
    folder = './snaps'
    for the_file in os.listdir(folder):
        file_path = os.path.join(folder, the_file)
        try:
            if os.path.isfile(file_path):
                os.unlink(file_path)
        except Exception as e:
            print(e)
    print('folder\'s clear, you may run lua script')

delete_previous_data()

def make_choice(my_choice):
    my_choice += 1
    try:
        file = open("lua_data.dat", "w")
        file.write(str(my_choice))
        file.close()
    except Exception:
        print("failed to write to lua_data")
        time.sleep(.050)
        make_choice(my_choice - 1)


make_choice(1)


def get_game_state(image):
    # preprocess the image before input into neural network
    # make image grayscale
    state = rgb2gray(image)
    # Normalizing, usually not a good idea to use amax since state might not contain max value
    # a better normalization formula is x - min(x) - average(x) / max(x) - min(x) since it centers around 0
    state = state.astype("float32") / np.amax(state)
    state = transform.resize(state, [STATE_X, STATE_Y])
    state = np.expand_dims(state, axis=0)
    return state


initial_state = graphics.get_initial_screen()
deep_q_agent = agent_test.DeepQNetwork((1, STATE_X, STATE_Y), initial_state, n_choices, q_learning_rate, gamma, temperature=TEMPERATURE)


def get_score():

    file = open("score.dat", "r")
    my_score = file.readline()
    file.close()

    if not my_score:  # score wasn't available yet
        time.sleep(.050)
        return get_score()
    else:
        return int(my_score)



reward = 0.0
previous_reward = -99
score = 0
previous_score = get_score()

high_score = get_score() + 1


def calculate_reward():
    global high_score
    global steps_no_improvement
    # if score < high_score:
    #     steps_no_improvement += 1
    if score == DEATH_SCORE:
        return DEATH_PENALTY
    score_difference = score - previous_score
    if score >= high_score and score_difference > 0:
        high_score = score
        return REWARD_VALUE
    elif score_difference > 0:
        return FORWARD_REWARD
    elif score_difference == 0:
        return STANDING_PENALTY
    else:
        return WRONG_DIR_PENALTY


def train_network():
    global image, score, reward, choice
    image = graphics(training=True)
    score = get_score()
    reward = calculate_reward()
    state = get_game_state(image)
    choice, _ = deep_q_agent.take_action(state, reward, training=True)


first_in_loop = True
while True:

    if not os.path.exists(cutscene_indicator):

        train_network()
        first_in_loop = True
    else:

        if first_in_loop:  # train the network if it just entered the loop just in case thats a death
            train_network()
            first_in_loop = False
        else:
            image = graphics(training=False)
            choice = 0
    previous_score = score
    make_choice(choice)

