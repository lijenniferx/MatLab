% GAPE_ARRAY 
% 1. Takes as input a cell array of EMG activity
% 2. Extracts the features for each movement, 
% 3. Runs the features through the lick/gape classification algorithm
% 4. Returns an equal-sized array  of 0s and 1s, where
%    the 1s indicate the timing of gapes (temporal resolution is 1 ms)
%
% INPUTS
% __emg:              A cell array of EMG activity (output of get_data)
% __onset_or_peak:    A string variable
%                    'onset'- 1 is placed at the onset of the gape
%                    'peak'-1 is placed at the peak of the gape
% OUTPUTS
% __gape_array:       A cell array of equal size as emg. 
%                     Each element of the cell array is a matrix with dimensions trial x time
% __movement_id:      A cell array of equal size as emg. Each element of
%                     cell array is a cell array that represents the trial
%                     number: movement_id{taste}{trial_number}. Each trial
%                     is a vector whose length is the number of movements.
%                     0's denote licks, and 1's gapes. 
% HELPER FUNCTIONS
% __burst_features(): Calculates the features for individual movements

%Written by Jennifer Li

function [gape_array,movement_id]=get_gapes(emg,onset_or_peak)

if nargin==1
    onset_or_peak='peak';
elseif ismember(onset_or_peak,['peak','onset'])
    onset_or_peak=onset_or_peak;
else
    error('Did not enter a correct value for the second argument.  Please enter "onset" or "peak".')
end

if ~iscell(emg)
    emg={emg};
end
                
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%% Getting the features for each movement: duration, etc
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    features=burst_features(emg); 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% Getting the criterion function
%%%% If the output of f_gape<0, then said movement is a gape
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    current_path=pwd;

    cd /Users/jenniferli/Documents/MatlabFunctions/KatzLab/EMG/
     load QDA_nostd_no_first
    coefs=important_coefficients;
    
    

    f_gape = @(x,y) coefs(1) + coefs(2)*x + coefs(3)*y ...
                    + coefs(4)*x.^2 + (coefs(5))*x.*y + coefs(6)*y.^2; 

     
    cd(current_path);
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%% 1. Using the features for each movement, classifies movement as lick or gape. 
%%%%%%%% 2. Produces array of 0s and 1s, where 1 indicates occurrence of a gape
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    trial_length=size(emg{1},2);
    
    
    
    for tastes=1:length(features) %% loop through each taste
        
        no_of_trials=size(features{tastes},2);
        gape_array{tastes}=zeros(no_of_trials,trial_length); %%% preallocating gape_array
        
        
        for trial=1:no_of_trials %% loop through each trial
            
            movement_id{tastes}{trial}=zeros(1,size(features{tastes}{trial},1)); %%% preallocating movement_id, all movements are initially licks by default and have value 0
            
            peak_time=features{tastes}{trial}(:,1);
            onset_time=features{tastes}{trial}(:,1)+features{tastes}{trial}(:,5);
            duration=features{tastes}{trial}(:,4);
            peak_to_peak=features{tastes}{trial}(:,7);
            
            condition_1=arrayfun(f_gape,peak_to_peak,duration)<0;  %%% applying the gape classification algorithm
            condition_2=ones(size(condition_1,1),size(condition_1,2)); condition_2(1)=0;  %% can't be the first movement
            
            
             conditions_all=condition_1&condition_2; %% both conditions must be met
            
            if strcmp(onset_or_peak,'peak')
                gape_array{tastes}(trial,peak_time(conditions_all))=1;  %%%% use peak  as time of gape
            else
                gape_array{tastes}(trial,onset_time(conditions_all))=1;  %%% use onset as time of gape
            end
            
            movement_id{tastes}{trial}(conditions_all)=1;  %% set movements corresponding to gapes to 1

            
        end
    end
end
            
