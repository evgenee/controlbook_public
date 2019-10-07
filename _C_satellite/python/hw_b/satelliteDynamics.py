import numpy as np 
import random
import satelliteParam as P


class satelliteDynamics:
    '''
        Model the physical system
    '''

    def __init__(self):
        # Initial state conditions
        self.state = np.array([
            [P.theta0],     # initial base angle
            [P.phi0],       # initial panel angle
            [P.thetadot0],  # initial angular velocity of base
            [P.phidot0],
        ])   # nitial angular velocity of panel
        self._Ts = P.Ts
        self._Js = P.Js  # inertia of base
        self._Jp = P.Jp  # inertia of panel
        self._k = P.k    # spring coefficient
        self._b = P.b    # Damping coefficient, Ns

    def update(self, u):
        # This is the external method that takes the input u at time
        # t and returns the output y at time t.
        self._rk4_step(u)  # propagate the state by one time sample
        y = self._h()  # return the corresponding output
        return y

    def _rk1_step(self, u):
        # Integrate ODE using Runge-Kutta RK1 algorithm
        self.state += self._Ts * self._f(self.state, u)

    def _rk2_step(self, u):
        # Integrate ODE using Runge-Kutta RK2 algorithm
        F1 = self._f(self.state, u)
        F2 = self._f(self.state + self._Ts / 2 * F1, u)
        self.state += self._Ts / 2 * (F1 + F2)

    def _rk4_step(self, u):
        # Integrate ODE using Runge-Kutta RK4 algorithm
        F1 = self._f(self.state, u)
        F2 = self._f(self.state + self._Ts / 2 * F1, u)
        F3 = self._f(self.state + self._Ts / 2 * F2, u)
        F4 = self._f(self.state + self._Ts * F3, u)
        self.state += self._Ts / 6 * (F1 + 2 * F2 + 2 * F3 + F4)

    def _f(self, state, u):
        '''
            Return xdot = f(x,u), the derivatives of the continuous states, as a matrix
        '''
        # re-label states and inputs for readability
        theta = state.item(0)
        phi = state.item(1)
        thetadot = state.item(2)
        phidot = state.item(3)
        tau = u
        # The equations of motion.
        M = np.matrix([[self._Js, 0],
                       [0, self._Jp]])
        C = np.matrix([[tau - self._b*(thetadot-phidot)-self._k*(theta-phi)],
                       [-self._b*(phidot-thetadot)-self._k*(phi-theta)]])
        tmp = np.linalg.inv(M)*C
        thetaddot = tmp.item(0)
        phiddot = tmp.item(1)
        # build xdot and return
        xdot = np.array([[thetadot], [phidot], [thetaddot], [phiddot]])
        return xdot

    def _h(self):
        '''
            Returns the measured outputs as a list
            [z, theta] with added Gaussian noise
        '''
        # re-label states for readability
        theta = self.state.item(0)
        phi = self.state.item(1)
        # # add Gaussian noise to outputs
        # theta_m = theta + random.gauss(0, 0.001)
        # phi_m = phi + random.gauss(0, 0.001)
        # return measured outputs
        y = np.array([[theta], [phi]])
        return y