% GET_FEATURES computes the following values for all movements within a trial:
% 1. Area under the envelope for each movement
% 2. Duration for each movement
% 3. Onset for each movement
% 4. Offset for each movement
% 5. 'duplicate' movements that need to be removed (if peak-to-peak time
%    is smaller than a certain threshold __small_time__)

function features=get_features(trial, peak_info,small_time,baseline)



         offsets=cat(1,100,diff(peak_info(:,1))); %%% peak-to-peak time for each movement
         bad_movements=[];       
         
         for movement=1:length(peak_info(:,1))
              
              %%%%% removing some duplicate movements 

               if offsets(movement)<small_time
                   if peak_info(movement,2)>peak_info(movement-1,2)  %%% current movement is bigger than former movement
                        bad_movements=cat(1,bad_movements,movement-1);  %% get rid of former movement
                   else
                       bad_movements=cat(1,bad_movements,movement); %%% get rid of current movement
                   end
               end
                              
               %%%% getting movement duration and area
               threshold=baseline(1)+0.0*baseline(2);
               
               duration_movements(movement)=length(falls_between(trial(peak_info(movement,1)-100:peak_info(movement,1)+100),101,threshold,1));%%% calculating duration of movement
               area_movements(movement)=nanmean(falls_between(trial(peak_info(movement,1)-100:peak_info(movement,1)+100),101,threshold,1));%%% calculating magnitude of movement
              
               if duration_movements(movement)==0
                        duration_movements(movement)=20;
                        area_movements(movement)=peak_info(movement,2);
               end
               
               %%%% calculating movement onset 
               if isempty(falls_between(trial(peak_info(movement,1)-100:peak_info(movement,1)+100),101,threshold,1))%%% peak is too small
                   onset_movements(movement)=-10;
               else
                   [~,junkz]=(falls_between(trial(peak_info(movement,1)-100:peak_info(movement,1)+100),101,threshold,1));
                   onset_movements(movement)=-junkz(1);
               end
               
               %%%% calculating movement offset 
               if isempty(falls_between(trial(peak_info(movement,1)-100:peak_info(movement,1)+100),101,threshold,1))%%% peak is too small
                   offset_movements(movement)=10;
               else
                   [~,junkz]=(falls_between(trial(peak_info(movement,1)-100:peak_info(movement,1)+100),101,threshold,1));
                   offset_movements(movement)=-junkz(end);
               end
               
         end
         
         %%% assigning outputs
         features.area=area_movements';         
         features.duration=duration_movements';
         features.onset=onset_movements';
         features.offset=offset_movements';
         features.bad_movements=bad_movements;
         
end
         
               