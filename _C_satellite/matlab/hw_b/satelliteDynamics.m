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
            self.Js = P.Js;  % inertia of base
            self.Jp = P.Jp;  % inertia of panel
            self.k = P.k;    % spring coefficient
            self.b = P.b;    % Damping coefficient, Ns
            self.Ts = P.Ts; % sample rate at which dynamics is propagated
          
        end
        %----------------------------
        function y = update(self, u)
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
            % return measured outputs
            y = [theta; phi];
        end
    end
end


