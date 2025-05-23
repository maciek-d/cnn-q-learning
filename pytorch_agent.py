import random
import numpy as np

import torch
import torch.nn as nn
import torch.nn.functional as torch_func
import torch.optim as optim

from torch.autograd import Variable

from collections import deque
MODEL_PATH = "./saved_models/"
class DeepQNetwork(nn.Module):
    step_count = 0
    def __init__(self, input_shape, n_outputs, learning_rate, gamma, temperature=1.0, epsilon=.99, epsilon_decay=.001):
        super(DeepQNetwork, self).__init__()

        # gamma is q learning rate or reward decay
        self.input_size = input_shape
        self.h1_size = 128
        self.out_size = n_outputs

        self.convolution1 = nn.Conv2d(in_channels=1, out_channels=32, kernel_size=5)
        self.convolution2 = nn.Conv2d(in_channels=32, out_channels=32, kernel_size=3)
        self.convolution3 = nn.Conv2d(in_channels=32, out_channels=64, kernel_size=2)
        # self.lstm = nn.LSTMCell(self.node_size(input_shape))

        self.h1 = nn.Linear(self.node_size(input_shape), self.h1_size)
        self.h2 = nn.Linear(self.h1_size, self.out_size)

        self.optimizer = optim.Adam(self.parameters(), lr=learning_rate)
        self.gamma = gamma
        self.epsilon = epsilon
        self.epsilon_decay = epsilon_decay
        self.temperature = temperature

    def node_size(self, image_dim):
        x = Variable(torch.rand(1, *image_dim))
        x = torch_func.elu(torch_func.max_pool2d(self.convolution1(x), 3, 2))
        x = torch_func.elu(torch_func.max_pool2d(self.convolution2(x), 3, 2))
        x = torch_func.elu(torch_func.max_pool2d(self.convolution3(x), 3, 2))
        return x.data.view(1, -1).size(1)


    def model(self, inputs):
        if len(inputs) > 1:
            inputs = torch.cat(inputs, 0)
        conv1 = torch_func.elu(torch_func.max_pool2d(self.convolution1(inputs), 3, 2))
        conv2 = torch_func.elu(torch_func.max_pool2d(self.convolution2(conv1), 3, 2))
        conv3 = torch_func.elu(torch_func.max_pool2d(self.convolution3(conv2), 3, 2))
        h1_in = conv3.view(conv3.size(0), -1)

        # h1 = torch.nn.Linear(h1_in.size(), self.h1_size)
        h1 = torch_func.relu(self.h1(h1_in))
        # h2 = torch.nn.Linear(self.h1_size, self.out_size)
        return self.h2(h1)

    def softmax_action(self, state, temperature):
        state_var = Variable(state, volatile=True).cuda()
        q_values = torch_func.softmax(self.model(state_var).cuda()*temperature, dim=1)
        action = q_values.multinomial(num_samples=1).data[0]
        return action, q_values.data.cpu().numpy()[0]

    @staticmethod
    def get_tensor_value(tensor):
        return tensor.data.cpu().numpy()[0]

    def epsilon_greedy_action(self, state):
        rand = random.random()
        if rand < self.epsilon:
            action = random.randint(0, (self.out_size - 1))
            self.epsilon -= self.epsilon_decay
            q_values = torch.Tensor(np.eye(self.out_size, dtype=np.float32)[action]*2).cuda()
            action = torch.LongTensor([action]).cuda().data[0]
        else:
            # softmax action with temperature 1 doesnt alter softmax probabilities
            action, q_values = self.softmax_action(state, 1.0)
        return action, q_values

    def convert_to_tensor(self, data):
        if isinstance(data, int):
            return torch.LongTensor([data]).cuda()
        elif isinstance(data, float):
            return torch.Tensor([data]).cuda()
        else:
            return torch.Tensor(data).unsqueeze(0).cuda()

    def train_batch(self, states, actions, rewards, next_states):
        actions = torch.cat(actions, 0)
        rewards = torch.cat(rewards, 0)
        outputs = self.model(states).cuda().gather(1, actions.unsqueeze(1)).squeeze(1)
        next_outputs = self.model(next_states).cuda().detach().max(1)[0]
        target = self.gamma * next_outputs + rewards
        self.optimizer.zero_grad()
        loss = torch_func.smooth_l1_loss(outputs, target)
        loss.backward()
        self.optimizer.step()
        if self.step_count % 1000 == 0:
            model_number = int(self.step_count / 1000)
            print(model_number)
            print(MODEL_PATH + "model" + str(model_number))
            torch.save({
            'epoch':  self.step_count,
            'model_state_dict': self.state_dict(),
            'optimizer_state_dict': self.optimizer.state_dict(),
            'loss': loss
            }, MODEL_PATH + "model" + str(model_number))
        self.step_count += 1