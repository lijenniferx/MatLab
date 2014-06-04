
function trials_keep=keep_significant_response(key_events,emg_data,emg_baseline,pre)

%%%% this function takes a cell array of EMG signals (__emg_data__) and a
%%%% cell array of taste delivery times (__key_events__), and identifies
%%%% the trials where the taste stimulus elicited a significant EMG response

    for taste=1:size(key_events,2) %% looping through the tastes
        %%% trials_with_emg are going to be the trial numbers for each taste where the emg response is bigger than baseline
    
            trials_keep{taste}=[];
       
    %%%  identifying the trials with a sufficiently large taste-evoked EMG signal 
    %%% (by comparing the poststimulus EMG signal with the baseline EMG signal)
            for trial=1:length(key_events{taste})
        
                if (mean(abs(emg_data{taste}(trial,pre:end)))>1*mean(emg_baseline))&&...  %%% mean EMG signal is greater than the mean baseline
                   (max(abs(emg_data{taste}(trial,pre:end)))>mean(emg_baseline)+4*std(emg_baseline)) %%% peak EMG signal is greater than 4 SDs above the mean baseline
                    trials_keep{taste}=cat(1,trials_keep{taste},trial);
                end

            end
    end
 
end