% BURST FEATURES takes an array of EMG responses, and does the following:
% 1. picks out individual movements
% 2. extracts a set of features for each movement
%
% INPUTS
% __emg:                      A cell array (trials x time) of EMG responses (The output of get_data())
% __pre (optional):           Analysis time prior to taste delivery (ms)
% __post(optional):           Analysis time following taste delivery (ms)ivery
%
% OUTPUTS
% __all_bursts:               A cell array, where the number in the first {} denotes
%                             the tastant ID, and the number in the second {} denotes the delivery number for that tastant.  
%                             all_bursts{4}{1} would return the 1st delivery for the 4th tastant.
%                             The 1st column is the PEAK TIME of the movement (in ms, relative to the beginning of the prestimulus period). 
%                             The 2nd column is the AMPLITUDE of the movement (size of peak, in uV). 
%                             The 3rd column is the MAGNITUDE of the movement (area under the curve).
%                             The 4th column is the DURATION of the movement (in ms). Minimum value is 20 ms.
%                             The 5th column is the ONSET of the movement (ms before the peak: default, a negative number)
%                             The 6th column is the OFFSET of the movement (ms after the peak: default, a positive number)
%                             The 7th column is the PEAK-TO-PEAK TIME for the movement (the larger of two possible values) 
%
% HELPER FUNCTIONS
% __convolve_by():           Smooths a vector with a rectangular filter.
% __peakdet():               Takes in a continuous vector, and detects peaks
% __get_features():          Calculates 1) area, 2) duration, 3) onset, 4) offset for each movement
% __remove_rows():           Eliminates select rows of an array, and returns the new array

% Written by Jennifer Li

function all_bursts=burst_features(emg, pre, post)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% some predefined variables
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%% checking that the inputs are in order
if nargin==1
    pre=1500;
    post=2600;
end

if ~iscell(emg)
    emg={emg};
end


%%%%%%%%%%%%%%%% parameters for generating the envelope

[c,d]=butter(3,0.03,'low');  %%% 0.05 is low pass filtering at 25 Hz, 0.03 is low pass filtering at 15 Hz
smoothing_window=1;%10; # if 1, does nothing


%%%%% parameters for detecting individual movements

param(1)=1;  %%% how "big" each peak has to be to be considered a separate movement (useed in peakdet())
param(2)=85; %%  maximum interval between two successive peaks that allows them to be counted as the same movement


%%%%% generating full set of baseline responses (for specifying when a movement begins and ends)
    baseline=[];
    for tastes=1:size(emg,2)
        baseline_responses{tastes}=reshape(abs(emg{tastes}(:,1:pre)),1,numel(emg{tastes}(:,1:pre)));
        baseline=cat(2,baseline,baseline_responses{tastes});
    end


%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%% EXTRACTING THE ENVELOPE OF THE EMG SIGNAL:  
%%%%%% 1. smoothing with a box (length: smoothing_window), 2. low-pass filtering (25 Hz)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%


baseline_envelope=[];

for i=1:size(emg,2)  %%% go through each taste
  
        %%% Step 1: rectifying traces, and then smoothing them
         
            smooth_emg{i}=convolve_by(abs(emg{i}),smoothing_window)./sum(smoothing_window);
            
        %%%% Step 2: low-pass filtering each trace
            for trial=1:size(emg{i},1)  %%% go through each trial within each taste 
            
                envelope{i}(trial,:)=filtfilt(c,d,smooth_emg{i}(trial,:));  
                
                %%% concatenating the baseline filtered signal into a single array
                baseline_envelope=cat(2,baseline_envelope,envelope{i}(trial,1:pre));
                
            end
    
    
end

%%%%%%%%%%%%%%%%%%%
%%%%% CALCULATING FEATURES FOR INDIVIDUAL BURSTS
%%%%%%%%%%%%%%%%%%
% 
     for taste=1:size(envelope,2)  %%% going through each taste
   
        for trial=1:size(envelope{taste},1)  %%% going through each delivery of each taste
        
     
        %%% calculating time of peak and amplitude of peak
         [peak_info_temp,~]=peakdet(envelope{taste}(trial,:),param(1)*std(baseline_envelope));  %%% peak_info_temp has two columns: 1) time of peak, 2) amplitude of peak
         
         peak_temp=peak_info_temp(find(peak_info_temp(:,1)>pre+100),:); %%% only look at mouth movements produced 100 ms after taste delivery
        
         peak_temp=peak_temp(find(peak_temp(:,1)<post+pre-100),:);  %%%% only look at mouth movements produced 100 ms before the end of the analysis period
        
         %%% calculating area, duration, onset, and offset  (movement cutoff is mean(baseline_envelope))
         trial_features=get_features(envelope{taste}(trial,:), peak_temp,param(2),[mean(baseline_envelope),std(baseline_envelope)]);
                 
          peak_temp(:,3)=trial_features.area;   
          peak_temp(:,4)=trial_features.duration'; 
          peak_temp(:,5)=trial_features.onset';   %%% how many ms to the left of the peak (negative values)
          peak_temp(:,6)=trial_features.offset';  %%% how many ms to the right of the peak (positive values)
          bad_movements=trial_features.bad_movements;
          
         %%%% getting rid of some duplicate movements         
         cleaned_up_movements=remove_rows(peak_temp,bad_movements);   
         all_bursts{taste}{trial}=cleaned_up_movements;  
          
          
           
         %%% getting the peak-to-peak interval
                 peak_to_peak=cat(1,100,diff(all_bursts{taste}{trial}(:,1)));
                 peak_to_peak=cat(1,peak_to_peak,100);
                 all_bursts{taste}{trial}(:,7)=1000./(max((cat(2,peak_to_peak(1:end-1),peak_to_peak(2:end)))'));  %%%% take larger of two intervals, convert to Hz
           
    
          
          
        end
     end
    
    %%%% returning array of features
    all_bursts=all_bursts;


end