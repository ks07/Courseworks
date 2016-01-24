classdef UAVPlotter < handle
    %UAVPLOTTER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        uav_count;
        uav_states; % [x,y,h;] * uav_count
        uav_colours; % RGB * uav_count
        uav_lcolours; % RGB * uav_count
        
        linelen; % Length of line to draw for UAV heading
        
        dbg_updated; % Used to check if every UAV has updated each timestep
    end
    
    methods
        function plotter = UAVPlotter(uav_count)
            colour = [0 1 1];
            cstep = 1 / uav_count;

            plotter.uav_count = uav_count;
            plotter.uav_states = zeros(uav_count, 3);
            plotter.uav_colours = zeros(uav_count, 3);
            plotter.uav_lcolours = zeros(uav_count, 3);
            for i = 1:uav_count
                plotter.uav_colours(i,:) = hsv2rgb(colour);
                plotter.uav_lcolours(i,:) = 1 - plotter.uav_colours(i,:);
                colour(1) = colour(1) + cstep;
            end
            
            plotter.linelen = 15;
            
            plotter.dbg_updated = zeros(uav_count,1);
        end
        function plot(self,id,pos,hdg)
            self.dbg_updated(id) = true;
            self.uav_states(id,:) = [pos, hdg];
        end
        function draw(self,t,cloud,mapDraw)
            % Check if all UAVs have actually done something this timestep!
            if min(self.dbg_updated) == false
                error('Some UAVs did not update this timestep!');
            end
            self.dbg_updated(:) = false;
            
            if mapDraw
                cla;
                
                % put information in the title
                ppm = cloudsamp(cloud,self.uav_states(1,1),self.uav_states(1,2),t);
                title(sprintf('t=%.1f secs pos=(%.1f, %.1f) Concentration=%.2f',t,self.uav_states(1,1),self.uav_states(1,2),ppm))

                % plot the cloud contours
                cloudplot(cloud,t);
            end
            
            % Plot position (Need loop else all will be one colour!)
            %plot(self.uav_states(:,1),self.uav_states(:,2),'o','Color',self.colour);
            for i=1:self.uav_count
                plot(self.uav_states(i,1),self.uav_states(i,2),'o','Color',self.uav_colours(i,:));
                
                % Plot heading
                hx = [self.uav_states(i,1),self.uav_states(i,1)+sind(self.uav_states(i,3))*self.linelen];
                hy = [self.uav_states(i,2),self.uav_states(i,2)+cosd(self.uav_states(i,3))*self.linelen];
                plot(hx, hy, 'Color', self.uav_lcolours(i,:));
            end
        end
    end
    
end

