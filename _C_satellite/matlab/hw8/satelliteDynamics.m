classdef satelliteDynamics < handle
    %  Model the physical system
    %----------------------------
    properties
        state
        Js
        Jp
        k
        b
        Ts
        torque_limit
    end
    %----------------------------
    methods
        %---constructor-------------------------
        function self = satelliteDynamics(P)
            % Initial state conditions
            self.state = [...
                        P.theta0;...      % initial base angle
                        P.phi0;...        % initial panel angle
                        P.thetadot0;...   % initial angular velocity of base
                        P.phidot0;...     % initial angular velocity of panel
                        ];     
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % The parameters for any physical system are never known exactly.  Feedback
            % systems need to be designed to be robust to this uncertainty.  In the simulation
            % we model uncertainty by changing the physical parameters by a uniform random variable
            % that represents alpha*100 % of the parameter, i.e., alpha = 0.2, means that the parameter
            % may change by up to 20%.  A different parameter value is chosen every time the simulation
            % is run.
            alpha = 0.0;  % Uncertainty parameter
            self.Js = P.Js * (1+2*alpha*rand-alpha);  % inertia of base
            self.Jp = P.Jp * (1+2*alpha*rand-alpha);  % inertia of panel
            self.k = P.k * (1+2*alpha*rand-alpha);    % spring coefficient
            self.b = P.b * (1+2*alpha*rand-alpha);    % Damping coefficient, Ns
            self.Ts = P.Ts; % sample rate at which dynamics is propagated
            self.torque_limit = P.tau_max;
        end
        %----------------------------
        function y = update(self, u)
            % saturate the input
            u = self.saturate(u, self.torque_limit);
            self.rk4_step(u);
            y = self.h();
        end
        %----------------------------
        function self = rk1_step(self, u)
            %
            % Integrate the differential equations defining dynamics
            % P.Ts is the time step between function calls.
            % u contains the system input(s).
            % 
            % Integrate ODE using Runge-Kutta RK1 algorithm
            self.state = self.state + self.Ts * self.f(self.state, u);
        end
        %----------------------------
        function self = rk2_step(self, u)
            %
            % Integrate the differential equations defining dynamics
            % P.Ts is the time step between function calls.
            % u contains the system input(s).
            % 
            % Integrate ODE using Runge-Kutta RK2 algorithm
            F1 = self.f(self.state, u);
            F2 = self.f(self.state + self.Ts/2 * F1, u);
            self.state = self.state + self.Ts/6 * (F1 + F2);
        end
        %----------------------------
        function self = rk4_step(self, u)
            %
            % Integrate the differential equations defining dynamics
            % P.Ts is the time step between function calls.
            % u contains the system input(s).
            % 
            % Integrate ODE using Runge-Kutta RK4 algorithm
            F1 = self.f(self.state, u);
            F2 = self.f(self.state + self.Ts/2*F1, u);
            F3 = self.f(self.state + self.Ts/2*F2, u);
            F4 = self.f(self.state + self.Ts*F3, u);
            self.state = self.state + self.Ts/6 * (F1 + 2*F2 + 2*F3 + F4);
        end
        %----------------------------
        function xdot = f(self, state, u)
            %
            % Return xdot = f(x,u), the derivatives of the continuous states, as a matrix
            % 
            % re-label states and inputs for readability
            theta = state(1);
            phi = state(2);
            thetadot = state(3);
            phidot = state(4);
            tau = u;
            % The equations of motion.
            M = [...
                self.Js, 0; 0, self.Jp;...
                ];
            c = [...
                tau - self.b*(thetadot-phidot)-self.k*(theta-phi);...
                -self.b*(phidot-thetadot)-self.k*(phi-theta);...
                ];
            tmp = M\c;
            thetaddot = tmp(1);
            phiddot = tmp(2);
            % build xdot and return
            xdot = [thetadot; phidot; thetaddot; phiddot];
        end
        %----------------------------
        function y = h(self)
            %
            % Returns the measured outputs as a list
            % [theta, phi] with added Gaussian noise
            % 
            % re-label states for readability
            theta = self.state(1);
            phi = self.state(2);
            % add Gaussian noise to outputs
            theta_m = theta + 0.001*randn;
            phi_m = phi + 0.001*randn;
            % return measured outputs
            y = [theta_m; phi_m];
        end
        %----------------------------
        function out = saturate(self, in, limit)
            if abs(in) > limit
                out = limit * sign(in);
            else 
                out = in;
            end
        end
    end
end


