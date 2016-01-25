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
        
        stat_oob; % Count of UAVs that have gone out of bounds.
        stat_coll; % Count of the number of collisions.
    end
    
    properties(Constant)
        POS_BOUNDS = 1000;
        COLL_LIM = 50;
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
            
            plotter.stat_oob = 0;
            plotter.stat_coll = 0;
        end
        function plot(self,id,pos,hdg)
            if max(abs(pos)) > self.POS_BOUNDS
                self.stat_oob = self.stat_oob + 1;
            end
            self.dbg_updated(id) = true;
            self.uav_states(id,:) = [pos, hdg];
        end
        function draw(self,t,cloud,mapDraw)
            % Check if all UAVs have actually done something this timestep!
            if min(self.dbg_updated) == false
                error('Some UAVs did not update this timestep!');
            end
            self.dbg_updated(:) = false;
            
            % Check for any collisions.
            if self.uav_count > 1
                combos = nchoosek(1:self.uav_count,2); % Use binomial to avoid symmetric checks!
                for ci=1:size(combos,1);
                    ai = combos(ci,1);
                    bi = combos(ci,2);
                    apos = self.uav_states(ai,1:2);
                    bpos = self.uav_states(bi,1:2);
                    abdist = pdist([apos;bpos]);
                    if abdist < self.COLL_LIM
                        self.stat_coll = self.stat_coll + 1;
                    end
                end
            end
            
            if mapDraw
                cla;
                
                % put information in the title
                title(sprintf('t=%.1f Collisions=%d OOB=%d',t,self.stat_coll,self.stat_oob))

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

