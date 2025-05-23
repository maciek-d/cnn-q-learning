import random
import pickle
import pytorch_agent as dqn


class ExperienceReplay:
    def __init__(self, max_capacity):
        self.max_capacity = max_capacity
        self.memory = []

    def size(self):
        return len(self.memory)

    def to_file(self):
        with open('experience_replay.dat', 'wb') as file:
            pickle.dump(self.memory, file)
        # to read back
        # with open('outfile', 'rb') as fp:
        #     itemlist = pickle.load(fp)

    def push(self, experience):
        self.memory.append(experience)
        if len(self.memory) > self.max_capacity:
            del self.memory[0]

    def fetch_batch(self, batch_size):
        return zip(*random.sample(self.memory, batch_size))


class DeepQNetwork():
    def __init__(self, input_shape, initial_state, n_outputs, learning_rate, gamma, temperature=1.0, epsilon=.99, epsilon_decay=.001):
        device = "cuda:0"
        self.temperature = temperature
        self.dqn = dqn.DeepQNetwork(input_shape, n_outputs, learning_rate, gamma, temperature, epsilon, epsilon_decay).to(device)
        self.experience_replay = ExperienceReplay(max_capacity=100000)  # 100000
        self.training_batch_size = 100
        self.previous_state = self.dqn.convert_to_tensor(initial_state)
        self.previous_action = self.dqn.convert_to_tensor(2)
        self.reward_memory = []
        self.state_memory = []
        self.action_memory = []
        self.reward_delay = 3

    def push_memory(self, memory):
        prev_state_tensor = self.dqn.convert_to_tensor(memory[0])
        prev_action_tensor = self.dqn.convert_to_tensor(memory[1])
        reward_tensor = self.dqn.convert_to_tensor(memory[2])
        state_tensor = self.dqn.convert_to_tensor(memory[3])
        self.experience_replay.push((prev_state_tensor, prev_action_tensor, reward_tensor, state_tensor))

    def take_action(self, state, reward, training=False):
        state = self.dqn.convert_to_tensor(state)
        if training:
            reward = self.dqn.convert_to_tensor(reward)
            action, q_values = self.dqn.softmax_action(state, self.temperature)
            self.reward_memory.append(reward)
            self.state_memory.append(state)
            self.action_memory.append(action)

            if len(self.reward_memory) > self.reward_delay:
                reward = self.reward_memory[self.reward_delay]
                state = self.state_memory[self.reward_delay - 1]
                self.previous_state = self.state_memory[self.reward_delay - 2]
                self.previous_action = self.action_memory[1]
                del self.reward_memory[0]
                del self.state_memory[0]
                del self.action_memory[0]
                # print(self.previous_action, '>>', reward)
                # input()
                self.experience_replay.push((self.previous_state, self.previous_action, reward, state))
            if self.experience_replay.size() > self.training_batch_size:
                prev_states, prev_actions, rewards, states = self.experience_replay.fetch_batch(self.training_batch_size)
                self.dqn.train_batch(prev_states, prev_actions, rewards, states)
        return self.dqn.get_tensor_value(action), q_values
